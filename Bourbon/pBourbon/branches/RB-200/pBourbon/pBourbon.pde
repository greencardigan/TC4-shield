// Title: pBourbon
// Roast logger with temperature on 2 channels and rate of rise on channel 1

// This is a Processing sketch intended to run on a host computer.

// MLG Properties, LLC Copyright (c) 2010, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php

// William Welch Copyright (c) 2009, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php
// Inspired by Tom Igoe's Grapher Pro: http://www.tigoe.net/pcomp/code/category/Processing/122
// and Tim Hirzel's BCCC Plotter: http://www.arduino.cc/playground/Main/BBCCPlotter

// acknowledgement for enhancements/corrections added by Brad Collins (greencardigan)

// version 20100806 by Jim Gallt
// added guide-profile 18 sept William Welch
// version 20101008 by Rama Roberts
// added a TC reading average to help with reported fluctuations
// version 20101023 by Jim Gallt
// added code to optionally turn off TC reading average (SAMPLESIZE = 1)

// Release 2.00 by Brad (mostly) and Jim (a little)
// -------------------------------------------------
// added code for Celsius mode
// added 'First Crack' and 'Second Crack' markers. 'F' and 'S'
// added code to scale temp axis in celsius mode if c_MAX_TEMP is changed
// added code to scale temp axis in fahrenheit mode if MAX_TEMP is changed
// added code to scale time axis if MAX_TIME is changed
// added 'Beans added' and 'End of roast' markers. 'B' and 'E'
// modified keyboard input code to accept 1 button markers  Requires 'Space' to enter other text
// added code to receive marker commands from aBourbon V2.00 and plot on graph
// added code to extend time axis by 2 minutes after time reaches MAX_TIME - 1 minute
// added RESET command to synchronize with TC4 (by Jim)
// added code to load and plot old logfiles in background

// Version 2.10
// ----------------
// added code for multiple resets to accommodate slow response from Uno board

// ************************************* User Preferences **************************************

// Optionally, plot a target roast profile to guide you
boolean enable_guideprofile = false; // set true to enable
//boolean enable_guideprofile = true; // set true to enable
//String PROFILE = "myprofile_c.csv";
String PROFILE = "myprofile.csv";

// Optionally, plot the results of an old roast that you want to duplicate
boolean enable_loadlogfile = false; // set true to enable
//boolean enable_loadlogfile = true; // set true to enable
String LOGFILE = "logfile.csv";
//String LOGFILE ="logfile_c.csv";

// make this as short as possible for good resolution;  depends on your roaster
int MINUTES = 17; // time limit for graph (change to suit)

// change the plot background color
//int CBGND = 64; // background color dark grey
int CBGND = 0;  // background color black

// **********************************************************************************************


String filename = "logs/roast" + nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + nf(hour(),2,0) + nf(minute(),2,0);
String CSVfilename = filename + ".csv";
PrintWriter logfile;
String appname = "Bourbon Roast Logger v2.10";

String cfgfilename = "pBourbon.cfg"; // whichport, baudrate

String profile_data[];
String logfile_data[];
String kb_note = "";

color c0 = color(255,0,0); // channel 0
color c1 = color(0,255,0);
color c2 = color(255,255,0);
color c3 = color(255,204,0);
color c4 = color(255,0,255);
color cmin = color( 0,255,255 );
color cidx = color( 0,255,255 );
color clabel = color( 255,255,160 );
color cgrid_maj = color(120,120,120); // major grid lines
color cgrid_min = color (90,90,90);
int cbgnd = CBGND;  // background color
color cloadlogfile_BT = color(150,0,0);
color cloadlogfile_BTROR = color(0,125,0);
color cloadlogfile_ET = color(150,150,0);

int NCHAN = 2;  // 2 input channels
// int START_DELAY = 2000; // ms to wait to be sure aBourbon sketch is up and running
int resetAck = 0;  // count RESET command acknowledgements

// default values for port and baud rate
String whichport = "COM1";
int baudrate = 57600;
boolean started;  // waits for a keypress to begin logging
boolean makeJPG = false; // flag for doing a frame grab in draw()

import processing.serial.*;
Serial comport;

int MAX_TEMP = 520;  // degrees (or 10 * degF per minute)
int c_MAX_TEMP = 290;
int MAX_TIME = 60 * MINUTES; // 60 seconds * minutes
int MIN_TEMP = -20; // degrees
int c_MIN_TEMP = -10; 

int TEMP_INCR = 20;  // degrees
int c_TEMP_INCR = 10; 
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

PFont c_labelFont;
PFont startFont;
PFont monitorFont;
PFont markerFont;
int templabelypos = 2; // text vertical position adjustment. Modified in celsius mode
int templabelxpos = 40; // text horizontal position adjustment. Modified in celsius mode
String corf = "Fahrenheit"; // C of F mode
float fc_x; // x position for first crack marker
float fc_y; // y position for first crack marker
float sc_x; // x position for second crack marker
float sc_y; // y position for second crack marker
float er_x; // x position for end of roast marker
float er_y; // y position for end of roast marker
float ba_x; // x position for beans added marker
float ba_y; // y position for beans added marker

String fcm = "FC"; // first crack marker
String scm = "SC"; // second crack marker
String erm = "E"; // End or roast/Eject marker
String bam = "B"; // Begin/Beans loaded marker

float temp_scale = 1.0; // 1 for fahrenheit mode
float time_scale = 1.0; // time axis scale factor if adjusting MAX_TIME


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
  if( lines.length >= 4 ) {
    String[] corfstring = split( lines[3], "," );
    if( corfstring[0].equals("C")) corf = "Celsius";
  };

  print( "COM Port: "); println( whichport );
  print( "Baudrate: "); println( baudrate );
  if( SAMPLESIZE > 1 ) {
    print( "TC average sample size: "); println( SAMPLESIZE );
  }
  print( "Fahrenheit or Celsius: "); println( corf ); println();
 

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
  c_labelFont = createFont("Tahoma-Bold", 12 );
  startFont = createFont("Tahoma-Bold", 16 );
  monitorFont = createFont("Tahoma-Bold", 16 );
  markerFont = createFont("Tahoma-Bold", 16 );


 fill( clabel );
  
  if ( corf.charAt(0) == 'C') {
    labelFont = c_labelFont;
    templabelypos = 1;
    templabelxpos = 25;
    temp_scale = float (520 - MIN_TEMP) / (c_MAX_TEMP - c_MIN_TEMP);
    MAX_TEMP = c_MAX_TEMP;
    MIN_TEMP = c_MIN_TEMP; // degrees
    TEMP_INCR = c_TEMP_INCR;  // degrees
  } else {
      temp_scale = float (520 - MIN_TEMP) / (MAX_TEMP - MIN_TEMP);
  }
  
  time_scale = 1020 / float (MAX_TIME); // calcs new time scale if MAX_TIME <> 1020 = 17 minutes
    
  size(1200, 800);
  frameRate(5); 
  smooth();
  background(cbgnd);

  if (enable_guideprofile) {
    profile_data = loadStrings(PROFILE);
  }
  if (enable_loadlogfile) {
    logfile_data = loadStrings(LOGFILE);
  }

} // setup


// --------------------------------------------------

// returns the average value for a given float array
// FIXME need to test change in loop limit (used to default to the array size, not to SAMPSIZE)
float arrayAverage(float[] T) {
  int sum = 0;
  for (int i=0; i < SAMPLESIZE; i++) {
     sum += T[i];
  }
  return (sum / SAMPLESIZE);
}


// --------------------------------------------------

void drawgrid(){
  textFont(labelFont);
  stroke(cgrid_maj);
  fill( clabel);
  
  // draw horizontal grid lines
  for (int i=MIN_TEMP + TEMP_INCR; i<MAX_TEMP; i+=TEMP_INCR) {
    text(nf(i,3,0), 0, (MAX_TEMP-i) * temp_scale - templabelypos);
    text(nf(i,3,0), MAX_TIME  * time_scale - templabelxpos, (MAX_TEMP-i) * temp_scale  - templabelypos);  // right side vert. axis labels
    line(0, (MAX_TEMP-i) * temp_scale, MAX_TIME * time_scale, (MAX_TEMP-i) * temp_scale);
  }
  
  // draw vertical grid lines
  int m;
  for (int i= 30 ; i<MAX_TIME; i+= 30) {
    if( i % 60 == 0 ) {
      m = i / 60;
      text(str(m), i * time_scale + 1, MAX_TEMP * temp_scale - MIN_TEMP * temp_scale - 2 );
      stroke(cgrid_maj);  // major gridlines should be a little bolder
    }
      else
        stroke(cgrid_min);
    line(i * time_scale, 0, i * time_scale, MAX_TEMP * temp_scale - MIN_TEMP * temp_scale);
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
    line(x1 * time_scale, (MAX_TEMP-y1) * temp_scale, x2 * time_scale, (MAX_TEMP-y2) * temp_scale);
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
    line(x1 * time_scale, (MAX_TEMP-y1) * temp_scale, x2 * time_scale, (MAX_TEMP-y2) * temp_scale);
    x1 = x2;
    y1 = y2;
  }
}

void drawlogfile() {

  if (logfile_data == null) return;
  float BT_x1, BT_y1, BT_x2, BT_y2;
  float BTROR_x1, BTROR_y1, BTROR_x2, BTROR_y2;
  float ET_x1, ET_y1, ET_x2, ET_y2;

  BT_x1 = 0;
  BT_y1 = 0;
  BTROR_x1 = 0;
  BTROR_y1 = 0;
  ET_x1 = 0;
  ET_y1 = 0;
  
  for (int i=0; i<logfile_data.length; i++) {
    String[] rec = split(logfile_data[i], ',');
    if (rec[0].charAt(0) == '#') {
      stroke(127,0,127);
      fill(127,0,127);
      if (rec[0].equals("# STRT")) {
        ellipse(float(rec[1]) * time_scale,(MAX_TEMP - BT_y1) * temp_scale,6,5);
      } else if (rec[0].equals("# FC")) {
        ellipse(float(rec[1]) * time_scale,(MAX_TEMP - BT_y1) * temp_scale,6,5);
      } else if (rec[0].equals("# SC")) {
        ellipse(float(rec[1]) * time_scale,(MAX_TEMP - BT_y1) * temp_scale,6,5);
      } else if (rec[0].equals("# EJCT")) {
        ellipse(float(rec[1]) * time_scale,(MAX_TEMP - BT_y1) * temp_scale,6,5);
      }
    }  
    else {
      BT_x2 = float(rec[0]);
      BT_y2 = float(rec[2]);
      BTROR_x2 = float(rec[0]);
      BTROR_y2 = float(rec[3]);
      ET_x2 = float(rec[0]);
      ET_y2 = float(rec[4]);
      stroke(cloadlogfile_BT);
      line(BT_x1 * time_scale, (MAX_TEMP-BT_y1) * temp_scale, BT_x2 * time_scale, (MAX_TEMP-BT_y2) * temp_scale);
      stroke(cloadlogfile_BTROR);
      line(BTROR_x1 * time_scale, (MAX_TEMP-(BTROR_y1 * 10)) * temp_scale, BTROR_x2 * time_scale, (MAX_TEMP-(BTROR_y2 * 10)) * temp_scale);
      stroke(cloadlogfile_ET);
      line(ET_x1 * time_scale, (MAX_TEMP-ET_y1) * temp_scale, ET_x2 * time_scale, (MAX_TEMP-ET_y2) * temp_scale);
      BT_x1 = BT_x2;
      BT_y1 = BT_y2;
      BTROR_x1 = BTROR_x2;
      BTROR_y1 = BTROR_y2;
      ET_x1 = ET_x2;
      ET_y1 = ET_y2;
    }
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
    textFont( monitorFont, t1 );
    text(strng,pos-w,16);
    strng = "TIME";
    textFont( monitorFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,32 );
  
    pos += incr;
    fill( c0 );
    strng = nf( T0[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( monitorFont, t1 );
    text(strng,pos-w,16);
    strng = "BEAN";
    textFont( monitorFont, t2 );
    text(strng,pos-w,32 );

    pos += incr;
    fill( c1 );
    strng = nfp( 0.1* T1[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( monitorFont, t1 );
    text(strng,pos-w,16);
    strng = "  RoR";
    textFont( monitorFont, t2 );
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
      textFont( monitorFont, t1 );
      text(strng,pos-w,16);
      strng = SAMPLESIZE + "s avg";
      textFont( monitorFont, t2 ); 
      w = textWidth( strng );
      text(strng,pos-w,32 );
    }
    
    pos += incr;
    fill( c2 );
    strng = nf( T2[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( monitorFont, t1 );
    text(strng,pos-w,16);
    strng = "ENV";
    textFont( monitorFont, t2 );
    text(strng,pos-w,32 );

/*
    pos += incr;
    fill( cidx );
    strng = nf( idx,4,0 );
    w = textWidth(strng);
    textFont( monitorFont, t1 );
    text(strng,pos-w,16);
    strng = "INDEX";
    textFont( monitorFont, t2 );
    text(strng,pos-w,32 );
*/

  }
}

void drawnote() {
  if (kb_note.length() > 0) {
    textFont(labelFont);
    fill(clabel);
    stroke(128,128,128);
    text(kb_note, 100, 100);
  }
}

void drawmarkers() { 

  textFont(markerFont,16);
  fill(c4);
  stroke(c4);
  float tw;
  
  if (fc_x != 0) {
    tw = textWidth(fcm);
    text(fcm, fc_x * time_scale - (tw/2) , fc_y * temp_scale -5);
    ellipse(fc_x * time_scale,fc_y * temp_scale,6,5);
  }
  if (sc_x != 0) {
    tw = textWidth(scm);
    text(scm, sc_x * time_scale - (tw/2) , sc_y * temp_scale -5);
    ellipse(sc_x * time_scale,sc_y * temp_scale,6,5);
  }
  if (er_x != 0) {
    tw = textWidth(erm);
    text(erm, er_x * time_scale - (tw/2) , er_y * temp_scale -5);
    ellipse(er_x * time_scale,er_y * temp_scale,6,5);
  }
  if (ba_x != 0) {
    tw = textWidth(bam);
    text(bam, ba_x * time_scale - (tw/2) , ba_y * temp_scale -5);
    ellipse(ba_x * time_scale,ba_y * temp_scale,6,5);
  }
}


// ------------------------------------------------------
void draw() {

  float sx = 1.;
  float sy = 1.;
  sx = float(width) / MAX_TIME / time_scale;
  sy = float(height) / (( MAX_TEMP - MIN_TEMP ) * temp_scale);
  scale(sx, sy);
  background( cbgnd );

  if( !started ) {
    textFont( startFont );
    text( appname + "\n" + corf + " Mode\nPress a key or click to begin logging ...\n",110, 110 );
  }
  else {
    drawgrid();
    drawprofile();
    drawlogfile();
    drawnote();
    drawchan(T0, c0 );  
    drawchan(T1, c1 );
    if( NCHAN >= 2 )   drawchan(T2, c2 );
    // if( NCHAN >= 2 )   drawchan(T3, c3 );   // don't draw RoR for 2nd channel
    drawmarkers();
   
    // put numeric monitor at top of screen
    monitor( 18, 16 );
    
    // grab a frame if request is queued
    if( makeJPG ) {
      saveFrame(filename + "-##" + ".jpg" );
      makeJPG = false;
    }
   
    if (timestamp > MAX_TIME - 60) {
      MAX_TIME = MAX_TIME + 120;
      time_scale = 1020 / float (MAX_TIME); // calcs new time scale if MAX_TIME <> 1020 = 17 minutes
     
      // extend arrays
      T0[0] = (float[]) expand(T0[0], T0[0].length + 120);
      T0[1] = (float[]) expand(T0[1], T0[1].length + 120);
      T1[0] = (float[]) expand(T1[0], T1[0].length + 120);
      T1[1] = (float[]) expand(T1[1], T1[1].length + 120);
      if( NCHAN >= 2 )   T2[0] = (float[]) expand(T2[0], T2[0].length + 120);
      if( NCHAN >= 2 )   T2[1] = (float[]) expand(T2[1], T2[1].length + 120);
      if( NCHAN >= 2 )   T3[0] = (float[]) expand(T3[0], T3[0].length + 120);
      if( NCHAN >= 2 )   T3[1] = (float[]) expand(T3[1], T3[1].length + 120);
    }
  } // end else
}

// -------------------------------------------------------------
void serialEvent(Serial comport) { // this is executed each time a line of data is received from the TC4

    // grab a line of ascii text from the logger
    String msg = comport.readStringUntil('\n');

    // exit right away if blank line
    if (msg == null) return; // *****************
    msg = trim(msg);
    if (msg.length() == 0) return; // ****************

    // otherwise, check first to see if it is a comment --------------------------------------------
    if (msg.charAt(0) == '#') { // this line is a comment
      logfile.println(msg); // write it to the log no matter what
      println(msg); // write it to the terminal no matter what     
      String[] rec = split(msg, ",");  // comma separated input list
      if( rec[0].equals( "# Reset" ) ) { // acknowledge, and count, RESET's echoed back from remote
        ++resetAck;    // count them for possible debugging use
      }
        else if( started ) { // skip these roast markers if logging hasn't been started by the user
        if (rec[0].equals("# STRT")) { 
          ba_x = T0[0][idx-1];
          ba_y = MAX_TEMP - T0[1][idx-1];
        } else if (rec[0].equals("# FC")) {
          fc_x = T0[0][idx-1];
          fc_y = MAX_TEMP - T0[1][idx-1];
        } else if (rec[0].equals("# SC")) {
          sc_x = T0[0][idx-1];
          sc_y = MAX_TEMP - T0[1][idx-1];
        } else if (rec[0].equals("# EJCT")) {
          er_x = T0[0][idx-1];
          er_y = MAX_TEMP - T0[1][idx-1];
          makeJPG = true;  // save an image for posterity at eject time
        }
      } // end if started (for roast markers)
    } // end if this line is a comment

    // not a comment, so process the line as data, but only if logging has been started by the user --------
    else if( started ) {
      String[] rec = split(msg, ",");  // comma separated input list
      if (rec.length != 2 * NCHAN + 3 ) {
        println("Ignoring unknown msg from logger: " + msg);
        return; // *******************
      } // end if
  
      timestamp = float(rec[0]);
      ambient = float(rec[1]);

      T0[0][idx] = timestamp;
      T0[1][idx] = float(rec[2]); 
      T1[0][idx] = timestamp;
      T1[1][idx] = float(rec[3]) * 10.0;  // exaggerate the rate traces
  
      if( NCHAN >= 2 ) {
        T2[0][idx] = timestamp;
        T2[1][idx] = float(rec[4]);
      } // end if
      if( NCHAN >= 2 ) {
        T3[0][idx] = timestamp;
        T3[1][idx] = float(rec[5]) * 10.0;  // exaggerate the rate traces
      }
  
      for (int i=0; i<(2 * NCHAN + 3); i++) {
        print(rec[i]);
        logfile.print(rec[i]);
        if (i < 2 * NCHAN +2 ) print(",");
        if (i < 2 * NCHAN +2 ) logfile.print(",");
      } // end for
  
      logfile.println();
      println();
  
      idx++; // increment the data array counter
      //idx = idx % MAX_TIME; // wrap the counter ?? FIXME:  test this
    } // end else if started
  
} // serialEvent

// ------------------------------- reset the Arduino, etc.
void resetRemote() {
//    delay( START_DELAY ); // make sure the remote has had time to get started
    println("\nSynchronising with remote:");
    int i = 0;
    while( resetAck == 0 && i < 10 ) {
      comport.write( "RESET\n" );  // issue command to the TC4 to synchronize clocks
      delay( 500 );
      i++;
    }
    print( resetAck ); println( " reset(s) required." );
    if( resetAck != 0 )
      started = true;
}

// ------------------------------- save a frame when mouse is clicked
void mouseClicked() {
  if( !started ) {  // waiting for user to begin logging
    resetRemote();
  }
  else {
    makeJPG = true;  // queue a request to save a frame
  }
}

// ---------------------------------------------
void keyPressed() { 
  
  if( !started ) { // waiting for user to begin logging
    resetRemote();
  }
  else {
    if (kb_note.length() == 0) {
      switch (key) {
        case 'F':
        case 'f': 
          fc_x = T0[0][idx-1];
          fc_y = MAX_TEMP - T0[1][idx-1];
          println("# FC," + timestamp);
          logfile.println("# FC," + timestamp);
          break;
        case 'S':
        case 's':
          sc_x = T0[0][idx-1];
          sc_y = MAX_TEMP - T0[1][idx-1];
          println("# SC," + timestamp);
          logfile.println("# SC," + timestamp);
          break;
        case 'E':
        case 'e':
          er_x = T0[0][idx-1];
          er_y = MAX_TEMP - T0[1][idx-1];
          println("# EJCT," + timestamp);
          logfile.println("# EJCT," + timestamp);
          makeJPG = true; // save an image for posterity at eject time
          break;
        case 'B':
        case 'b':
          ba_x = T0[0][idx-1];
          ba_y = MAX_TEMP - T0[1][idx-1];
          println("# STRT," + timestamp);
          logfile.println("# STRT," + timestamp);
          break;
        case ' ':
          kb_note = "# ";
          break;
        default:
          println("Invalid Character");
          break;                  
      }
    } else
        if (( key == 13) || (key == 10) )  {
          if (kb_note.length() > 0) {
            println(kb_note + "," + timestamp);
            logfile.println(kb_note + "," + timestamp);
            kb_note = "";
          };
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
//  comport.bufferUntil('\n'); 
//  println( "buffering..." );
};

// ---------------------------------------------------
void stop() {
  if( started ) saveFrame(filename + "-##" + ".jpg" );  // save an image for posterity at exit
  comport.stop();
  logfile.flush();
  logfile.close();
  println("Data was written to: " + CSVfilename);
}

