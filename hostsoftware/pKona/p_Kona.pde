// Title: p_Kona
// 
// based on pBourbon.pde version 20100707 by Jim Gallt

// changed by Randy Tsuchiyama to also read in setpoint from the com port, and save to the log file
// also changed to read a variable length set of numbers from the serial port, instead of a fixed length set
// this makes it easier to change the Arduino side to add more information to send over, and have it stored in the log file.
// Roast logger with temperature on 2 channels and rate of rise on channel 1

// This is a Processing sketch intended to run on a host computer.

// MLG Properties, LLC Copyright (c) 2010, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php

// William Welch Copyright (c) 2009, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php
// Inspired by Tom Igoe's Grapher Pro: http://www.tigoe.net/pcomp/code/category/Processing/122
// and Tim Hirzel's BCCC Plotter: http://www.arduino.cc/playground/Main/BBCCPlotter



String filename = "../logs/roast" + nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + nf(hour(),2,0) + nf(minute(),2,0);
String CSVfilename = filename + ".csv";
PrintWriter logfile;
String appname = "Kona PID Roast Logger v1.01";

String cfgfilename = "p_Kona.cfg"; // whichport, baudrate

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
String whichport = "COM2";
int baudrate = 57600;
boolean started;  // waits for a keypress

import processing.serial.*;
Serial comport;


int idx = 0;
float timestamp = 0.0;
float setpoint = 0;
float step=0;
float countdown=0;
float delta_temp = 0;
float ct = 0;
float mt = 0;
float output = 0;

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
  // note that I arbitrarily am making these arrays larger then max time, so when the time is exceeded, 
  // there is no overflow condition.
  T0 = new float[2][(BUFFER_SIZE)];
  T1 = new float[2][(BUFFER_SIZE)];
  if( NCHAN >= 2 )   T2 = new float[2][(BUFFER_SIZE)];
  if( NCHAN >= 2 )   T3 = new float[2][(BUFFER_SIZE)];
  
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
// called by draw, draws graph for one channel
void drawchan(float [][] T, color c) {
  for (int i=1; i<idx; i++) {
    float x1 = T[0][i-1];
    float y1 = T[1][i-1];
    float x2 = T[0][i];
    float y2 = T[1][i];
    
    // bound the temp data to be plotted
    if (y1 > MAX_TEMP) y1 = MAX_TEMP;
    if (y2 > MAX_TEMP) y2 = MAX_TEMP;   
    if (y1 < MIN_TEMP) y1 = MIN_TEMP;
    if (y2 < MIN_TEMP) y2 = MIN_TEMP;
    
    //bound the time data
    if (x1 > MAX_TIME) {x1 = MAX_TIME;}
    if (x2 > MAX_TIME) {x2 = MAX_TIME;}
    
    stroke(c);
    line(x1, MAX_TEMP-y1, x2, MAX_TEMP-y2);
//		}
    }
}

// ------------------------- alphanumeric values at top of screen
void monitor( int t1, int t2 ) {
  int minutes,seconds;
  
  if( idx > 0 ) {
    String strng;
    float w;
    int iwidth = width;    //from above "size(1200, 800);", so width is 1200
    int incr = iwidth / 10;  
    int pos = incr;
  
//write time

    fill(clabel);
//    fill( cmin );
    seconds = int( T0[0][idx-1] ) % 60;
    minutes = int ( T0[0][idx-1] ) / 60;;
    strng = nf( minutes,2,0 ) + ":" + nf(seconds,2,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);            //text (data, x posn, y posn)
    strng = "TIME";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,32 );
  
//write chan 1 temp (MT)
    pos += incr;                   // increment x posn  
    fill(clabel);
//    fill( c0 );
    strng = nf( T0[1][idx-1],2,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "MT (ch 1)";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

//write chan 1 ror, (MT ROR)
    pos += incr;
	fill(clabel);
    //fill( c1 );
    strng = nfp( 0.1* T1[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "MT RoR ch1";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

//write ch 2 temp (CT)
    pos += incr;
    fill(clabel);	
    //fill( c2 );
    strng = nf( T2[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "CT (ch 2)";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

//write setpoint
    pos += incr;
    fill(clabel);	
    //fill( cidx );
    strng = nf( setpoint,3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "SetPoint";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

//write step number
    pos += incr;
    fill(clabel);
//    fill( c0 );
    strng = nf( step,2,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);            //text (data, x posn, y posn)
    strng = "Step";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,32 );

//write countdown timer
    pos += incr;
    fill(clabel);	
    //fill( c1 );
    strng = nf( countdown,3,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);            //text (data, x posn, y posn)
    strng = "Countdown";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,32 );

//write delta temp
    pos = incr;                    //reset position to left of screen, for 2nd row
    fill(clabel);
	//    fill( c0 );
    strng = nf( delta_temp,3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,64);            //text (data, x posn, y posn)
    strng = "Delta T";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,80 );

//write output to heater
    pos += incr;
    fill(clabel);	
    strng = nf( output,3,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,64);            //text (data, x posn, y posn)
    strng = "Heat Out";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,80 );
	
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
    text( appname + "\nPress a key or click to begin Arduino program ...\n",110, 110 );
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
  msg = trim(msg);               //trim spaces, tabs, cr, lf etc from msg
  if (msg.length() == 0) return;

  // always store in file - good for debugging, version-tracking, etc.
  //logfile.println(msg);

  if (msg.charAt(0) == '#') {   //check if debug message
	//next char is E only for end of roast message, all other debug messages are space for 2nd char.
  	if (msg.charAt(1) == 'E') {   //if end of roast message, save log file and take snapshot of screen
               textFont( labelFont );
               text( "\n" +  "\n" +  "\n" +  "\n" + "\nEnding Roast",110, 110 );

    		logfile.println(msg);
    		println(msg);
    		logfile.println(msg);
    		println(msg);
  		logfile.flush();
  		logfile.close();
  		println("End roast, data was written to: " + CSVfilename);
		saveFrame(filename + "-##" + ".jpg" );
    		return;
  		}
	else {
    		logfile.println(msg);
    		println(msg);
    		return;
  		}
	}
  
  String[] rec = split(msg, ",");  // comma separated input list, split msg into an array

/* rec[0]=time,  rec[1]=ambient temp, rec[2]=tmp ch1(mt),  rec[3]=ror 1,  rec[4]=tmp ch 2(ct), rec[5]=ror 2,
   rec[6]=setpoint, rec[6]=step number, rec[8]=countdown timer
*/

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
  
  ct = float (rec [4]); 
    
  setpoint = float (rec[6]);
  
  step = float (rec[7]);
  
  countdown = float (rec[8]);
  
  output = float (rec[9]);
  
  delta_temp = setpoint - ct; //delta temp is setpoint - ct
  
//read in as many numbers per line as is sent by the Arduino program, and send to logfile
  for (int i=0; i<(rec.length); i++) {
    print(rec[i]);
    logfile.print(rec[i]);
    if (i < (rec.length)) print(",");
    if (i < (rec.length)) logfile.print(",");
  }
  
// send delta temp to the log file at the end of the arduino sent data  
  logfile.print(delta_temp);
  logfile.println();
  println();
  
  idx++;
   // idx = idx % MAX_TIME;
  idx = idx % BUFFER_SIZE;  //keep idx from overflowing
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
  println("Closing window, data was written to: " + CSVfilename);
}


