// Title: pBourbon
// Roast logger with temperature on 2 channels and rate of rise on channel 1

// This is a Processing sketch intended to run on a host computer.

// MLG Properties, LLC Copyright (c) 2010, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php

// William Welch Copyright (c) 2009, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php
// Inspired by Tom Igoe's Grapher Pro: http://www.tigoe.net/pcomp/code/category/Processing/122
// and Tim Hirzel's BCCC Plotter: http://www.arduino.cc/playground/Main/BBCCPlotter

// version 20100806 by Jim Gallt
// added guide-profile 18 sept William Welch
// version 20101008 by Rama Roberts
// added a TC reading average to help with reported fluctuations
// version 20101023 by Jim Gallt
// added code to optionally turn off TC reading average (SAMPSIZE = 1)

// added code for Celsius mode // *** added by Brad
// added 'First Crack' and 'Second Crack' markers. 'F' and 'S' // *** added by Brad
// added code to scale temp axis in celsius mode if c_MAX_TEMP is changed // *** added by Brad
// added code to scale temp axis in fahrenheit mode if MAX_TEMP is changed // *** added by Brad
// added code to scale time axis if MAX_TIME is changed // *** added by Brad
// added 'Beans added' and 'End of roast' markers. 'B' and 'E' // *** added by Brad


String filename = "logs/roast" + nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + nf(hour(),2,0) + nf(minute(),2,0);
String CSVfilename = filename + ".csv";
PrintWriter logfile;
String appname = "Bourbon Roast Logger v1.03";

String cfgfilename = "pBourbon.cfg"; // whichport, baudrate

boolean enable_guideprofile = false; // set true to enable
String PROFILE = "myprofile.csv";
String profile_data[];
String kb_note = "";

color c0 = color(255,0,0); // channel 0
color c1 = color(0,255,0);
color c2 = color(255,255,0);
color c3 = color(255,204,0);
color c4 = color(255,0,255); // *** added by Brad
color cmin = color( 0,255,255 );
color cidx = color( 0,255,255 );
color clabel = color( 255,255,160 );
color cgrid_maj = color(120,120,120); // major grid lines
color cgrid_min = color (90,90,90);
int cbgnd = 0;  // background color black

int NCHAN = 2;  // 2 input channels

// default values for port and baud rate
String whichport = "COM1";
int baudrate = 57600;
boolean started;  // waits for a keypress to begin logging

import processing.serial.*;
Serial comport;

int MAX_TEMP = 520;  // degrees (or 10 * degF per minute)
int c_MAX_TEMP = 290; // *** added by Brad
int MAX_TIME = 60 * 20; // 60 seconds * minutes // *** MODIFIED by Brad
int MIN_TEMP = -20; // degrees
int c_MIN_TEMP = -10;  // *** added by Brad

int TEMP_INCR = 20;  // degrees
int c_TEMP_INCR = 10;  // *** added by Brad
int idx = 0;
float timestamp = 0.0;
float tstart = 0.0;

float ambient;
float power;
float [][] T0;
float [][] T1;
float [][] T2;
float [][] T3;

PFont labelFont;

int SAMPLESIZE = 20; // how many seconds we want to look back for the average
float [] T1_avg = new float[SAMPLESIZE]; // the previous T1 values
int avg_idx = 0; // index to our rolling window


PFont c_labelFont; // *** added by Brad
PFont startFont; // *** added by Brad
PFont monitorFont; // *** added by Brad
PFont markerFont; // *** added by Brad
int templabelypos = 2; // text vertical position adjustment. Modified in celsius mode // *** added by Brad
int templabelxpos = 40; // text horizontal position adjustment. Modified in celsius mode // *** added by Brad
String corf = "Fahrenheit"; // C of F mode // *** added by Brad
float fc_x; // x position for first crack marker // *** added by Brad
float fc_y; // y position for first crack marker // *** added by Brad
float sc_x; // x position for second crack marker // *** added by Brad
float sc_y; // y position for second crack marker // *** added by Brad
float er_x; // x position for end of roast marker // *** added by Brad
float er_y; // y position for end of roast marker // *** added by Brad
float ba_x; // x position for beans added marker // *** added by Brad
float ba_y; // y position for beans added marker // *** added by Brad

String fcm = "FC"; // first crack marker // *** added by Brad
String scm = "SC"; // second crack marker // *** added by Brad
String erm = "E"; // first crack marker // *** added by Brad
String bam = "B"; // second crack marker // *** added by Brad

float temp_scale = 1.0; // 1 for fahrenheit mode // *** added by Brad
float time_scale = 1.0; // time axis scale factor if adjusting MAX_TIME // *** added by Brad


// ----------------------------------------
void setup() {
  
  // open the logfile early to avoid race condition in SerialEvent handler
  println(CSVfilename);
  logfile = createWriter(CSVfilename);

  started = false; // don't plot until started; keep timestamp == 0
  
  // read com port settings from config file
  // format is: value, comment/n
  String[] lines = loadStrings( cfgfilename );
  SAMPLESIZE = 1; // default value in case sample size not given in config file
  if( lines.length >= 1 ) {
    String[] portstring = split( lines[0], "," );
    whichport = portstring[0];
  };
  if( lines.length >= 2 ) {
    String[] baudstring = split( lines[1], "," );
    baudrate = int( baudstring[0] );
  };
  if( lines.length >= 3 ) {
    String[] sampsize = split( lines[2], "," );
    SAMPLESIZE = int( sampsize[0] );
  };
  if( lines.length >= 4 ) { // *** added by Brad
    String[] corfstring = split( lines[3], "," );
    if( corfstring[0].equals("C")) corf = "Celsius";
  };

  print( "COM Port: "); println( whichport );
  print( "Baudrate: "); println( baudrate );
  if( SAMPLESIZE > 1 ) {
    print( "TC average sample size: "); println( SAMPLESIZE );
  }
  print( "Fahrenheit or Celsius: "); println( corf ); println(); // *** added by Brad
 

  // initialize the COM port (this can take a loooooong time on some computers)
  println("Initializing COM port.  Please stand by....");
  startSerial();
  
  // create arrays
  T0 = new float[2][MAX_TIME];
  T1 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T2 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T3 = new float[2][MAX_TIME];
  
  frame.setResizable(true);
  labelFont = createFont("Tahoma-Bold", 16 );
  c_labelFont = createFont("Tahoma-Bold", 12 ); // *** added by Brad
  startFont = createFont("Tahoma-Bold", 16 ); // *** added by Brad
  monitorFont = createFont("Tahoma-Bold", 16 ); // *** added by Brad
  markerFont = createFont("Tahoma-Bold", 16 ); // *** added by Brad


 fill( clabel );
  
  if ( corf.charAt(0) == 'C') { // *** added by Brad
    labelFont = c_labelFont; // *** added by Brad
    templabelypos = 1; // *** added by Brad
    templabelxpos = 25; // *** added by Brad
    temp_scale = float (520 - MIN_TEMP) / (c_MAX_TEMP - c_MIN_TEMP); // *** added by Brad
    MAX_TEMP = c_MAX_TEMP; // *** added by Brad
    MIN_TEMP = c_MIN_TEMP; // degrees // *** added by Brad
    TEMP_INCR = c_TEMP_INCR;  // degrees // *** added by Brad
  } else {
      temp_scale = float (520 - MIN_TEMP) / (MAX_TEMP - MIN_TEMP); // *** added by Brad
  }
  
  time_scale = 1020 / float (MAX_TIME); // calcs new time scale if MAX_TIME <> 1020 = 17 minutes // *** added by Brad
    
  size(1200, 800);
  frameRate(5);  // *** MODIFIED by Brad
  smooth();
  background(cbgnd);

  if (enable_guideprofile) {
    profile_data = loadStrings(PROFILE);
  }



} // setup


// --------------------------------------------------

// returns the average value for a given float array
// FIXME needs to have the array size passed as an argument in case SAMPSIZE not default value?
float arrayAverage(float[] T) {
  int sum = 0;
  for (int i=0; i < T.length; i++) {
     sum += T[i];
  }
  return (sum / T.length);
}


// --------------------------------------------------

void drawgrid(){
  textFont(labelFont);
  stroke(cgrid_maj);
  fill( clabel);
  
  // draw horizontal grid lines
  for (int i=MIN_TEMP + TEMP_INCR; i<MAX_TEMP; i+=TEMP_INCR) {
    text(nf(i,3,0), 0, (MAX_TEMP-i) * temp_scale - templabelypos); // *** MODIFIED by Brad
    text(nf(i,3,0), MAX_TIME  * time_scale - templabelxpos, (MAX_TEMP-i) * temp_scale  - templabelypos);  // right side vert. axis labels // *** MODIFIED by Brad
    line(0, (MAX_TEMP-i) * temp_scale, MAX_TIME * time_scale, (MAX_TEMP-i) * temp_scale); // *** MODIFIED by Brad
  }
  
  // draw vertical grid lines
  int m;
  for (int i= 30 ; i<MAX_TIME; i+= 30) {
    if( i % 60 == 0 ) {
      m = i / 60;
      text(str(m), i * time_scale, MAX_TEMP * temp_scale - MIN_TEMP * temp_scale - 2 ); // *** MODIFIED by Brad
      stroke(cgrid_maj);  // major gridlines should be a little bolder
    }
      else
        stroke(cgrid_min);
    line(i * time_scale, 0, i * time_scale, MAX_TEMP * temp_scale - MIN_TEMP * temp_scale); // *** MODIFIED by Brad
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
    line(x1 * time_scale, (MAX_TEMP-y1) * temp_scale, x2 * time_scale, (MAX_TEMP-y2) * temp_scale); // *** MODIFIED by Brad
  }
}
void drawprofile() {
  if (profile_data == null) return;
  int x1, y1, x2, y2;
  stroke(200,200,200);
  x1 = 0;
  y1 = 0;
  for (int i=0; i<profile_data.length; i++) {
    String[] rec = split(profile_data[i], ',');
    x2 = int(rec[0]);
    y2 = int(rec[1]);
    // println("x1,y1,x2,y2 " + x1 + " " + y1 + " " + x2 + " " + y2 );
    line(x1 * time_scale, (MAX_TEMP-y1) * temp_scale, x2 * time_scale, (MAX_TEMP-y2) * temp_scale); // *** MODIFIED by Brad
    x1 = x2;
    y1 = y2;
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
    textFont( monitorFont, t1 ); // *** MODIFIED by Brad
    text(strng,pos-w,16);
    strng = "TIME";
    textFont( monitorFont, t2 ); // *** MODIFIED by Brad
    w = textWidth( strng );
    text(strng,pos-w,32 );
  
    pos += incr;
    fill( c0 );
    strng = nf( T0[1][idx-1],2,1 );
    w = textWidth(strng);
    textFont( monitorFont, t1 ); // *** MODIFIED by Brad
    text(strng,pos-w,16);
    strng = "BEAN";
    textFont( monitorFont, t2 ); // *** MODIFIED by Brad
    text(strng,pos-w,32 );

    pos += incr;
    fill( c1 );
    strng = nfp( 0.1* T1[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( monitorFont, t1 ); // *** MODIFIED by Brad
    text(strng,pos-w,16);
    strng = "  RoR";
    textFont( monitorFont, t2 ); // *** MODIFIED by Brad
    w = textWidth( strng );
    text(strng,pos-w,32 );

    // T1 RoR Average
    // move this logic somewhere else, serialEvent() ?
    if( SAMPLESIZE > 1 ) {
      if (avg_idx == SAMPLESIZE) avg_idx = 0; // put our pointer at the beginning
      T1_avg[avg_idx] = T1[1][idx-1];
      avg_idx++;

      pos += incr;
      fill( c1 );
      strng = nfp( 0.1* arrayAverage(T1_avg),3,1 );
      w = textWidth(strng);
      textFont( monitorFont, t1 ); // *** MODIFIED by Brad
      text(strng,pos-w,16);
      strng = SAMPLESIZE + "s avg";
      textFont( monitorFont, t2 );  // *** MODIFIED by Brad
      w = textWidth( strng );
      text(strng,pos-w,32 );
    }
    
    pos += incr;
    fill( c2 );
    strng = nf( T2[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( monitorFont, t1 ); // *** MODIFIED by Brad
    text(strng,pos-w,16);
    strng = "ENV";
    textFont( monitorFont, t2 ); // *** MODIFIED by Brad
    text(strng,pos-w,32 );

/*
    pos += incr;
    fill( cidx );
    strng = nf( idx,4,0 );
    w = textWidth(strng);
    textFont( monitorFont, t1 ); // *** MODIFIED by Brad
    text(strng,pos-w,16);
    strng = "INDEX";
    textFont( monitorFont, t2 ); // *** MODIFIED by Brad
    text(strng,pos-w,32 );
*/

  }
}

void drawnote() {
  if (kb_note.length() > 0) {
    textFont(labelFont);
    stroke(128,128,128);
    text(kb_note, 100, 100);
  }
}

void drawmarkers() {  // *** Added by Brad
  if (fc_x != 0) {
    textFont(markerFont);
    fill(c4);
    stroke(c4);
    float tw = textWidth(fcm);
    text(fcm, fc_x * time_scale - (tw/2) , fc_y * temp_scale -5);
    ellipse(fc_x * time_scale,fc_y * temp_scale,5,5/temp_scale);
  }
  if (sc_x != 0) {
    textFont(markerFont);
    fill(c4);
    stroke(c4);
    float tw = textWidth(scm);
    text(scm, sc_x * time_scale - (tw/2) , sc_y * temp_scale -5);
    ellipse(sc_x * time_scale,sc_y * temp_scale,5,5/temp_scale);
  }
  if (er_x != 0) {
    textFont(markerFont);
    fill(c4);
    stroke(c4);
    float tw = textWidth(erm);
    text(erm, er_x * time_scale - (tw/2) , er_y * temp_scale -5);
    ellipse(er_x * time_scale,er_y * temp_scale,5,5/temp_scale);
  }
  if (ba_x != 0) {
    textFont(markerFont);
    fill(c4);
    stroke(c4);
    float tw = textWidth(bam);
    text(bam, ba_x * time_scale - (tw/2) , ba_y * temp_scale -5);
    ellipse(ba_x * time_scale,ba_y * temp_scale,5,5/temp_scale);
  }
}


// ------------------------------------------------------
void draw() {
  
  float sx = 1.;
  float sy = 1.;
  sx = float(width) / MAX_TIME / time_scale;
  sy = float(height) / (( MAX_TEMP - MIN_TEMP ) * temp_scale); // *** MODIFIED by Brad
  scale(sx, sy);
  background( cbgnd );

  if( !started ) {
    textFont( startFont );
    text( appname + "\n" + corf + " Mode\nPress a key or click to begin logging ...\n",110, 110 ); // *** MODIFIED by Brad
  }
  else {
   drawgrid();
   drawprofile();
   drawnote();
   drawchan(T0, c0 );  
   drawchan(T1, c1 );
   drawmarkers(); // *** added by Brad
   
   if( NCHAN >= 2 )   drawchan(T2, c2 );
   // if( NCHAN >= 2 )   drawchan(T3, c3 );   // don't draw RoR for 2nd channel

   // put numeric monitor at top of screen
   monitor( 18, 16 );
  }; // end else
}

// -------------------------------------------------------------
void serialEvent(Serial comport) {

    // grab a line of ascii text from the logger and sanity check it.
    String msg = comport.readStringUntil('\n');
    if (msg == null) return; // *****************
    msg = trim(msg);
    if (msg.length() == 0) return; // ****************

    //always store in file - good for debugging, version-tracking, etc.
    //logfile.println(msg);

    if (msg.charAt(0) == '#') {
      logfile.println(msg);
      println(msg);
      return; // ******************
    }
  
    String[] rec = split(msg, ",");  // comma separated input list
    if (rec.length != 2 * NCHAN + 3 ) {
      println("Ignoring unknown msg from logger: " + msg);
      return; // *******************
    }
  
    timestamp = float(rec[0]);
    if( !started ) tstart = timestamp;
    timestamp -= tstart;
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
  
    for (int i=0; i<(2 * NCHAN + 3); i++) {
      print(rec[i]);
      logfile.print(rec[i]);
      if (i < 2 * NCHAN +2 ) print(",");
      if (i < 2 * NCHAN +2 ) logfile.print(",");
    }
  
    logfile.println();
    println();
  
    idx++;
    idx = idx % MAX_TIME;

} // serialEvent

// ------------------------------- save a frame when mouse is clicked
void mouseClicked() {
  if( !started ) { started = true; }
  else {
   saveFrame(filename + "-##" + ".jpg" );
  };
}

// ---------------------------------------------
void keyPressed()
{ 
  if( !started )  { started = true; }
  else {

    // fixme -- add specific behavior for F (first crack), S (second crack), and E (eject) keys

    if (( key == 13) || (key == 10) )  {
      if (kb_note.length() > 1) { // *** MODIFIED by Brad
        println("# " + timestamp + " " + kb_note);
        logfile.println("# " + timestamp + " " + kb_note);
        
      } else if (kb_note.length() == 1) { // *** added by Brad
        switch (kb_note.charAt(0)) {
          case 'F':
          case 'f': 
            println(fc_x);
            fc_x = T0[0][idx-1];
            fc_y = MAX_TEMP - T0[1][idx-1];
            println("# " + timestamp + " First Crack");
            logfile.println("# " + timestamp + " First Crack");
            break;
          case 'S':
          case 's':
            sc_x = T0[0][idx-1];
            sc_y = MAX_TEMP - T0[1][idx-1];
            println("# " + timestamp + " Second Crack");
            logfile.println("# " + timestamp + " Second Crack");
            break;
          case 'E':
          case 'e':
            er_x = T0[0][idx-1];
            er_y = MAX_TEMP - T0[1][idx-1];
            println("# " + timestamp + " End of roast");
            logfile.println("# " + timestamp + " End of roast");
            break;
          case 'B':
          case 'b':
            ba_x = T0[0][idx-1];
            ba_y = MAX_TEMP - T0[1][idx-1];
            println("# " + timestamp + " Beans added");
            logfile.println("# " + timestamp + " Beans added");
            break;
          default:
            println("Invalid Character");
            break;
          }
      }
    kb_note = ""; // *** MODIFIED by Brad
  
    } else if (key != CODED) {
      kb_note = kb_note + key;
    }
  }
}

// ------------------------------------------
void startSerial() {
  comport = new Serial(this, whichport, baudrate);
  println( whichport + " comport opened.");
  comport.clear();
  println( "comport clear()'ed." );
  comport.bufferUntil('\n'); 
  println( "buffering..." );
};

// ---------------------------------------------------
void stop() {
  comport.stop();
  logfile.flush();
  logfile.close();
  println("Data was written to: " + CSVfilename);
}

