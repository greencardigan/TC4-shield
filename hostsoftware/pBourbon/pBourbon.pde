// Title: pBourbon
// Roast logger with temperature on 2 channels and rate of rise on channel 1

// This is a Processing sketch intended to run on a host computer.

// MLG Properties, LLC Copyright (c) 2010, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php

// William Welch Copyright (c) 2009, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php
// Inspired by Tom Igoe's Grapher Pro: http://www.tigoe.net/pcomp/code/category/Processing/122
// and Tim Hirzel's BCCC Plotter: http://www.arduino.cc/playground/Main/BBCCPlotter

// version 20100707 by Jim Gallt

String filename = "logs/roast" + nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + nf(hour(),2,0) + nf(minute(),2,0);
String CSVfilename = filename + ".csv";
PrintWriter logfile;
String appname = "Bourbon Roast Logger v1.00";

String cfgfilename = "pBourbon.cfg"; // whichport, baudrate

color c0 = color(255,0,0); // channel 0
color c1 = color(0,255,0);
color c2 = color(255,255,0);
color c3 = color(255,204,0);
color cmin = color( 0,255,255 );
color cidx = color( 0,255,255 );
color clabel = color( 255,255,160 );
color cgrid_maj = color(120,120,120); // major grid lines
color cgrid_min = color (90,90,90);
int cbgnd = 80;  // background color

int NCHAN = 2;  // 2 input channels

// default values for port and baud rate
String whichport = "COM1";
int baudrate = 57600;
boolean started;  // waits for a keypress

import processing.serial.*;
Serial comport;

int MAX_TEMP = 520;  // degrees (or 10 * degF per minute)
int MAX_TIME = 1020; // seconds
int MIN_TEMP = -20; // degrees
int TEMP_INCR = 20;  // degrees
int idx = 0;
float timestamp = 0.0;

float ambient;
float [][] T0;
float [][] T1;
float [][] T2;
float [][] T3;

PFont labelFont;

// ----------------------------------------
void setup() {
  
  // read com port settings from config file
  // format is: value, comment/n
  String[] lines = loadStrings( cfgfilename );
  if( lines.length >= 1 ) {
    String[] portstring = split( lines[0], "," );
    whichport = portstring[0];
  };
  if( lines.length >= 2 ) {
    String[] baudstring = split( lines[1], "," );
    baudrate = int( baudstring[0] );
  };

  print( "COM Port: "); println( whichport );
  print( "Baudrate: "); println( baudrate );
  
  // create arrays
  T0 = new float[2][MAX_TIME];
  T1 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T2 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T3 = new float[2][MAX_TIME];
  
  frame.setResizable(true);
  labelFont = createFont("Tahoma-Bold", 16 );
  fill( clabel );
  
  println(CSVfilename);
  logfile = createWriter(CSVfilename);

  size(1200, 800);
  frameRate(1);
  smooth();
  background(cbgnd);

  started = false;  // force a key press to begin reading from serial port

} // setup

// --------------------------------------------------
void drawgrid(){
  textFont(labelFont);
  stroke(cgrid_maj);
  fill( clabel);
  
  // draw horizontal grid lines
  for (int i=MIN_TEMP + TEMP_INCR; i<MAX_TEMP; i+=TEMP_INCR) {
    text(nf(i,3,0), 0, MAX_TEMP-i - 2);
    text(nf(i,3,0), MAX_TIME -40, MAX_TEMP-i - 2);  // right side vert. axis labels
    line(0, MAX_TEMP-i, MAX_TIME, MAX_TEMP-i);
  }
  
  // draw vertical grid lines
  int m;
  for (int i= 30 ; i<MAX_TIME; i+= 30) {
    if( i % 60 == 0 ) {
      m = i / 60;
      text(str(m), i, MAX_TEMP - MIN_TEMP - 2 );
      stroke(cgrid_maj);  // major gridlines should be a little bolder
    }
      else
        stroke(cgrid_min);
    line(i, 0, i, MAX_TEMP - MIN_TEMP);
  }
}

// --------------------------------------------------------
void drawchan(float [][] T, color c) {
  for (int i=1; i<idx; i++) {
    float x1 = T[0][i-1];
    float y1 = T[1][i-1];
    float x2 = T[0][i];
    float y2 = T[1][i];
    
    // bound the data to be plotted
    if (y1 > MAX_TEMP) y1 = MAX_TEMP;
    if (y2 > MAX_TEMP) y2 = MAX_TEMP;   
    if (y1 < MIN_TEMP) y1 = MIN_TEMP;
    if (y2 < MIN_TEMP) y2 = MIN_TEMP;
    stroke(c);
    line(x1, MAX_TEMP-y1, x2, MAX_TEMP-y2);
  }
}

// ------------------------- alphanumeric values at top of screen
void monitor( int t1, int t2 ) {
  int minutes,seconds;
  
  if( idx > 0 ) {
    String strng;
    float w;
    int iwidth = width;
    int incr = iwidth / 8;
    int pos = incr;
  
    fill( cmin );
    seconds = int( T0[0][idx-1] ) % 60;
    minutes = int ( T0[0][idx-1] ) / 60;;
    strng = nf( minutes,2,0 ) + ":" + nf(seconds,2,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "TIME";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,32 );
  
    pos += incr;
    fill( c0 );
    strng = nf( T0[1][idx-1],2,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "CHAN_1";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

    pos += incr;
    fill( c1 );
    strng = nfp( 0.1* T1[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "  RoR_1";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,32 );

    pos += incr;
    fill( c2 );
    strng = nf( T2[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "CHAN_2";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

/*
    pos += incr;
    fill( cidx );
    strng = nf( idx,4,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "INDEX";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );
*/

  }
}

// ------------------------------------------------------
void draw() {
  float sx = 1.;
  float sy = 1.;
  sx = float(width) / MAX_TIME;
  sy = float(height) / ( MAX_TEMP - MIN_TEMP );
  scale(sx, sy);
  background( cbgnd );

  if( !started ) {
    textFont( labelFont );
    text( appname + "\nPress a key or click to begin logging ...\n",110, 110 );
  }
  else {
   drawgrid();
   drawchan(T0, c0 );  
   drawchan(T1, c1 ); 
   if( NCHAN >= 2 )   drawchan(T2, c2 );
   // if( NCHAN >= 2 )   drawchan(T3, c3 );   // don't draw RoR for 2nd channel

   // put numeric monitor at top of screen
   monitor( 18, 16 );
  };
}

// -------------------------------------------------------------
void serialEvent(Serial comport) {
  // grab a line of ascii text from the logger and sanity check it.
  String msg = comport.readStringUntil('\n');
  if (msg == null) return;
  msg = trim(msg);
  if (msg.length() == 0) return;

  // always store in file - good for debugging, version-tracking, etc.
  //logfile.println(msg);

  if (msg.charAt(0) == '#') {
    logfile.println(msg);
    println(msg);
    return;
  }
  
  String[] rec = split(msg, ",");  // comma separated input list
  if (rec.length != 2 * NCHAN + 2 ) {
    println("Ignoring unknown msg from logger: " + msg);
    return;
  }
  
  timestamp = float(rec[0]);
  ambient = float(rec[1]);

  T0[0][idx] = timestamp;
  T0[1][idx] = float(rec[2]); 
  T1[0][idx] = timestamp;
  T1[1][idx] = float(rec[3]) * 10.0;  // exaggerate the rate traces
  
  if( NCHAN >= 2 ) {
    T2[0][idx] = timestamp;
    T2[1][idx] = float(rec[4]);
  }
  if( NCHAN >= 2 ) {
    T3[0][idx] = timestamp;
    T3[1][idx] = float(rec[5]) * 10.0;  // exaggerate the rate traces
  };
  
  for (int i=0; i<(2 * NCHAN + 2); i++) {
    print(rec[i]);
    logfile.print(rec[i]);
    if (i < 2 * NCHAN +1 ) print(",");
    if (i < 2 * NCHAN +1 ) logfile.print(",");
  }
  
  logfile.println();
  println();
  
  idx++;
  idx = idx % MAX_TIME;
} // serialEvent

// ------------------------------- save a frame when mouse is clicked
void mouseClicked() {
  if( !started ) {
    startSerial();
  }
  else {
   saveFrame(filename + "-##" + ".jpg" );
  };
}

// ---------------------------------------------
void keyPressed()
{ 
  if( !started )  {
   startSerial();
  }
  else {
  // fixme -- add specific behavior for F (first crack), S (second crack), and E (eject) keys
   println(timestamp + " key " + key);
   logfile.println(timestamp + " key " + key);
  };
}

// ------------------------------------------
void startSerial() {
  started = true;

  textFont( labelFont );
  text( appname + "\nPress a key or click to begin logging ..." 
    + "\nOpening serial port (this may take several seconds) ...",110, 110 );

  comport = new Serial(this, whichport, baudrate);
  println( whichport + " comport opened.");
  comport.clear();
  println( "comport clear()'ed." );
  comport.bufferUntil('\n'); 
  println( "buffering..." );
};

// ---------------------------------------------------
void stop() {
  if( started ) comport.stop();
  logfile.flush();
  logfile.close();
  println("Data was written to: " + CSVfilename);
}

