//Title: pBourbon
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
// added code to support fan speed and messages on serial port  PF
// added code to select guide profile from csv file list in sketch directory

final boolean useAddon = true; //use addon.pde if desired added 10-15 PF


String filename = "logs/roast" + nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + nf(hour(),2,0) + nf(minute(),2,0);
String CSVfilename = filename + ".csv";
PrintWriter logfile;
String appname = "Bourbon Roast Logger v1.04 RC2";

String cfgfilename = "pBourbon.cfg"; // whichport, baudrate

boolean enable_guideprofile = true; // set true to enable
String PROFILE = "myprofile.csv";
String profile_data[];
String kb_note = "";
/////////////used for guide profiles/////////////////////////////
int itemSelected = 0;
int recordCount;
int baseProfile = 0;
final int MAXPROFILEPAGE = 13;
ArrayList fileNames;

//color c0 = color(255,0,0); // channel 0
color c0 = color(10,10,255);  //changed to blue for visibility
color c1 = color(0,255,0);
color c2 = color(255,255,0);
color c3 = color(255,204,0);
color cmin = color( 0,255,255 );
color cidx = color( 0,255,255 );
color clabel = color( 255,255,160 );
color cgrid_maj = color(120,120,120); // major grid lines
color cgrid_min = color (90,90,90);
int cbgnd = 0;  // background color black
color white = color(255,255,255);
color blue = color(10,10,255);  //color for message ke
color green= color(53,227,41);



int NCHAN = 2;  // 2 input channels

// default values for port and baud rate
String whichport = "COM1";
int baudrate = 57600;
boolean started;  // waits for a keypress to begin logging

import processing.serial.*;
Serial comport;

int ADD_FIELDS=4;  //set to 3 if not using fan speed control otherwise 4


int MAX_TEMP = 520;  // degrees (or 10 * degF per minute)
//int MAX_TIME = 1020; // seconds
int MAX_TIME = 19 * 60; // minutes*seconds per minute=total seconds
//int MIN_TEMP = -20; // degrees 
int MIN_TEMP = 20; // degrees
int TEMP_INCR = 20;  // degrees
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
PFont selectFont;

int SAMPLESIZE = 20; // how many seconds we want to look back for the average
float [] T1_avg = new float[SAMPLESIZE]; // the previous T1 values
int avg_idx = 0; // index to our rolling window


// ----------------------------------------
void setup() {

  // open the logfile early to avoid race condition in SerialEvent handler
  println(CSVfilename);
  logfile = createWriter(CSVfilename);

  started = false; // don't plot until started; keep timestamp == 0
  //filenames[0] = "None"; 
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

  print( "COM Port: "); 
  println( whichport );
  print( "Baudrate: "); 
  println( baudrate );
  if( SAMPLESIZE > 1 ) {
    print( "TC average sample size: "); 
    println( SAMPLESIZE );
  }

  // initialize the COM port (this can take a loooooong time on some computers)
  println("Initializing COM port.  Please stand by....");
  //startSerial();

  // create arrays
  T0 = new float[2][MAX_TIME];
  T1 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T2 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T3 = new float[2][MAX_TIME];

  frame.setResizable(true);

  labelFont = createFont("Tahoma-Bold", 16 );
  selectFont = createFont("Tahoma-Bold", 24 );
  fill( clabel );

  //  size(1200, 800);
  // size(1200, 725, OPENGL);
  //size(1200, 725,P3D);
  size(1200, 725);
  //  frameRate(1);
  frameRate(60);
  smooth();
  background(cbgnd);

  if (enable_guideprofile) {
    dirListing();
    //  println("getting data from " + PROFILE);
    //    profile_data = loadStrings(PROFILE);
    // Define and create image button
    PImage b = loadImage("base1.gif");
    PImage r = loadImage("roll1.gif");
    PImage d = loadImage("down1.gif");
    // int x = width/2 - b.width/2;
    //  int y = height/2 - b.height/2; 
    int x = 50;
    int y = 30;
    if(recordCount > MAXPROFILEPAGE) {
      y = MAXPROFILEPAGE * 30 +38;
    }
    else {
      y = recordCount * 30 +38;
    }

    int w = b.width;
    int h = b.height;
    if(recordCount > 8) {
      h = h +48;
      y = y - 20;
    }
    //println("button y= "+y);
    gifbutton = new ImageButtons(x, y, w, h, b, r, d);
    printProfiles();
    //lets add a mouse wheel
    addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
      public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
        mouseWheel(evt.getWheelRotation());
      }
    }
    );
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

void drawgrid() {
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
    //added line below to track postion
    x_pos=x2;
  }
}
void drawprofile() {
  if (profile_data == null) return;
  int x1, y1, x2, y2;
  stroke(200,200,200);
  x1 = 0;
  y1 = 0;
  for (int i=1; i<profile_data.length; i++) {
    String[] rec = split(profile_data[i], ',');
    x2 = int(rec[0]);
    y2 = int(rec[1]);
    // println("x1,y1,x2,y2 " + x1 + " " + y1 + " " + x2 + " " + y2 );
    line(x1, MAX_TEMP-y1, x2, MAX_TEMP-y2);
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
    minutes = int ( T0[0][idx-1] ) / 60;
    ;
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
    strng = "BEAN";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

    pos += incr;
    fill( c1 );
    strng = nfp( 0.1* T1[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "  RoR";
    textFont( labelFont, t2 );
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
      textFont( labelFont, t1 );
      text(strng,pos-w,16);
      strng = SAMPLESIZE + "s avg";
      textFont( labelFont, t2 );
      w = textWidth( strng );
      text(strng,pos-w,32 );
    }

    pos += incr;
    fill( c2 );
    strng = nf( T2[1][idx-1],3,1 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);
    strng = "ENV";
    textFont( labelFont, t2 );
    text(strng,pos-w,32 );

    if (profile_data != null) {
      pos += incr;
    
      w = width - textWidth( PROFILE )-120;
      text(PROFILE,w,16 );
    }

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

/* useAddon  //used drawnote fron addon.pde 
 void drawnote() {
 if (kb_note.length() > 0) {
 textFont(labelFont);
 stroke(128,128,128);
 text(kb_note, 100, 100);
 }
 }
 #endif
 */

// ------------------------------------------------------
void draw() {
  float sx = 1.;
  float sy = 1.;
  sx = float(width) / MAX_TIME;
  sy = float(height) / ( MAX_TEMP - MIN_TEMP );
  scale(sx, sy);
  background( cbgnd );
  textFont(selectFont);

  if( !started ) { 

    if( enable_guideprofile == false) {
      textFont( labelFont );
      text( appname + "\nPress a key or click to begin logging ...\n",110, 110 );
    }
    else { 

      //   textFont(selectFont);  
      gifbutton.update();
      gifbutton.display();

      printProfiles();
      noLoop();
    }
  }
  else {
    drawgrid();
    drawprofile();
    drawnote();
    drawchan(T0, c0 );  
    drawchan(T1, c1 ); 
    if( NCHAN >= 2 )   drawchan(T2, c2 );
    // if( NCHAN >= 2 )   drawchan(T3, c3 );   // don't draw RoR for 2nd channel

    // put numeric monitor at top of screen
    monitor( 18, 16 );

    if (useAddon == true) {
      if (endTimer > 0) {
        if (  timestamp >(endTimer + endTimerSeconds)) {  //Time to end?
          endTimer = 0;
          logfile.println();
          logfile.println("End of roast timeout");
          //saveFrame(filename + "autoend" + ".jpg" ); //make graph of roast
          if (profile_data != null) {
            String fname = "logs/"+ PROFILE+ " "  + nf(month(),2,0) +"-" + nf(day(),2,0)+"-"+ nf(year(),4,0)+" " + nf(hour(),2,0) + nf(minute(),2,0);
            saveFrame(fname + ".jpg" ); //make graph of roast
          }
          else {
            saveFrame(filename + "autoend" + ".jpg" ); //make graph of roast
          }
          //stop();
          exit();
        }
        else {
          println ("Closing in " + ((endTimer + endTimerSeconds)- timestamp) + " seconds");
        }
      }
    }
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
  if(useAddon == true) {
    //added to process message from serial port
    String[] m1 = match(msg, "%%%");
    if( m1 != null) {
      println(msg);
      msgRecevided(msg.charAt(3));  //from addon.pde
      return;
    }
  } 

  String[] rec = split(msg, ",");  // comma separated input list

  if (rec.length != 2 * NCHAN + ADD_FIELDS ) {
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

  for (int i=0; i<(2 * NCHAN + ADD_FIELDS); i++) {
    print(rec[i]);
    logfile.print(rec[i]);
    if (i < 2 * NCHAN +( ADD_FIELDS -1) ) print(",");
    if (i < 2 * NCHAN +( ADD_FIELDS -1)) logfile.print(",");
  }

  if (useAddon == true) {
    if (msgflag > 0) {  //add to log if event key was pressed
      logfile.print(",");
      logfile.print(message[msgflag]);
      print(",");
      print(message[msgflag]);
      msgflag = 0;
    }
  }

  logfile.println();
  println();

  idx++;
  idx = idx % MAX_TIME;
}// serialEvent



// ---------------------------------------------

/* use keypressed from addon.pde
 void keyPressed()
 { 
 if( !started ) { 
 started = true;
 }
 else {
 
 // fixme -- add specific behavior for F (first crack), S (second crack), and E (eject) keys
 
 if (( key == 13) || (key == 10) ) {
 if (kb_note.length() > 0) {
 println("# " + timestamp + " " + kb_note);
 logfile.println("# " + timestamp + " " + kb_note);
 kb_note = "";
 }
 } 
 else if (key != CODED) {
      kb_note = kb_note + key;
 }
 }
 }
 */

// ------------------------------------------
void startSerial() {
  //  println(Serial.list());
  //  comport = new Serial(this, Serial.list()[3],  baudrate);
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

  if (useAddon == true) { 
    if (profile_data != null) {
      File ff=new File(sketchPath +"/" +CSVfilename);
      String newname=(sketchPath + "/logs/" + PROFILE + " "  + nf(month(),2,0) +"-" + nf(day(),2,0)+"-"+ nf(year(),4,0)+" " + nf(hour(),2,0) + nf(minute(),2,0)+".csv");
      ff.renameTo(new File(newname));
      println(CSVfilename + " renamed to "+ newname);
    }
    else {
      saveFrame(filename + ".jpg" ); //make graph of roast
    }
  }
}

