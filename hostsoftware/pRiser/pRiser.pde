// Title: Datalogger and real-time display of rate of temperature rise
// This is a Processing sketch intended to run on a host computer.

// Author: William Welch Copyright (c) 2009, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php
// Inspired by Tom Igoe's Grapher Pro: http://www.tigoe.net/pcomp/code/category/Processing/122
// and Tim Hirzel's BCCC Plotter: http://www.arduino.cc/playground/Main/BBCCPlotter

// version 0.1  01 July 2010

// modified 01 July 2010 by Jim Gallt

String logfilename = "roast_" + year()+"_"+month()+"_"+day()+"_"+hour()+"_"+minute()+"_"+second()+".csv";
PrintWriter logfile;

int NCHAN = 2;  // 2 input channels
int whichport = 3;
int baudrate = 57600;
import processing.serial.*;
Serial comport;

int MAX_TEMP = 500;  // degrees (or 10 * degF per minute)
int MAX_TIME = 900; // seconds
int MIN_TEMP = -100; // degrees
int TEMP_INCR = 20;  // degrees
int idx = 0;
float timestamp = 0.0;

float [][] T0;
float [][] T1;
float [][] T2;
float [][] T3;

PFont labelFont;

// ----------------------------------------
void setup() {
  // create arrays
  T0 = new float[2][MAX_TIME];
  T1 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T2 = new float[2][MAX_TIME];
  if( NCHAN >= 2 )   T3 = new float[2][MAX_TIME];
  
  frame.setResizable(true);
  labelFont = createFont("Courier", 18 );
  
  println(logfilename);
  logfile = createWriter(logfilename);

  // size(screen.width, screen.height);
  size(800, 600);
  frameRate(1);
  smooth();
  background(0);

  // FIXME: add menu to choose com port from the list.
  println(Serial.list());
  comport = new Serial(this, Serial.list()[whichport], baudrate);
  comport.clear();
  comport.bufferUntil('\n');
} // setup

// --------------------------------------------------
void drawgrid(){
  textFont(labelFont);
  stroke(128,128,128);
  
  // draw horizontal grid lines
  for (int i=MIN_TEMP + TEMP_INCR; i<MAX_TEMP; i+=TEMP_INCR) {
    // float xi = i * 1.0;
    text(str(i), 0, MAX_TEMP-i);
    line(0, MAX_TEMP-i, MAX_TIME, MAX_TEMP-i);
  }
  
  // draw vertical grid lines
  for (int i= 60 ; i<MAX_TIME; i+= 60) {
    int m = i / 60;
    text(str(m), i, MAX_TEMP);
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

// ---------------------------------------------
void keyPressed()
{
  println(timestamp + " key " + key);
  logfile.println(timestamp + " key " + key);
}

// ------------------------------------------------------
void draw() {
  float sx = 1.;
  float sy = 1.;
  sx = float(width) / MAX_TIME;
  sy = float(height) / ( MAX_TEMP - MIN_TEMP );
  scale(sx, sy);
  background(0);
  drawgrid();

  drawchan(T0, color(255,0,0) );  
  drawchan(T1, color(0,255,0) ); 
  if( NCHAN >= 2 )   drawchan(T2, color(0,0,255) );
  if( NCHAN >= 2 )   drawchan(T3, color(255,204,0) );  
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
  if (rec.length != 2 * NCHAN + 1 ) {
    println("Ignoring unknown msg from logger: " + msg);
    return;
  }
  
  timestamp = float(rec[0]);
  T0[0][idx] = timestamp;
  T0[1][idx] = float(rec[1]); 
  T1[0][idx] = timestamp;
  T1[1][idx] = float(rec[2]) * 10.0;  // exaggerate the rate traces
  
  if( NCHAN >= 2 ) {
    T2[0][idx] = timestamp;
    T2[1][idx] = float(rec[3]);
  }
  if( NCHAN >= 2 ) {
    T3[0][idx] = timestamp;
    T3[1][idx] = float(rec[4]) * 10.0;  // exaggerate the rate traces
  };
  
  for (int i=0; i<(2 * NCHAN + 1); i++) {
    print(rec[i]);
    logfile.print(rec[i]);
    if (i < 2 * NCHAN ) print(",");
    if (i < 2 * NCHAN ) logfile.print(",");
  }
  
  logfile.println();
  println();
  
  idx++;
  idx = idx % MAX_TIME;
} // serialEvent

// ---------------------------------------------------
void stop() {
  comport.stop();
  logfile.flush();
  logfile.close();
  println("Data was written to: " + logfilename);
}

