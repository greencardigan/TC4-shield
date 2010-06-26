// Title: Datalogger and real-time display
// Author: William Welch Copyright (c) 2010, all rights reserved.
// MIT license: http://opensource.org/licenses/mit-license.php
// Inspired by Tom Igoe's Grapher Pro: http://www.tigoe.net/pcomp/code/category/Processing/122
// and Tim Hirzel's BCCC Plotter: http://www.arduino.cc/playground/Main/BBCCPlotter

// version 0.1  20 May 2010

String logfilename = "roast_" + year()+"_"+month()+"_"+day()+"_"+hour()+"_"+minute()+"_"+second()+".csv";
PrintWriter logfile;

int whichport = 0;
int baudrate = 57600;
import processing.serial.*;
Serial comport;

int MAX_TEMP = 900; // fixme: support both F and C on plots.
int MAX_TIME = 1200;
// int MAX_TEMP = 800; // fixme: support both F and C on plots.
// int MAX_TIME = 30*60;
int idx = 0;
int [][] ambient = new int[2][MAX_TIME];
int [][] T0 = new int[2][MAX_TIME];
int [][] T1 = new int[2][MAX_TIME];
int [][] T2 = new int[2][MAX_TIME];
int [][] T3 = new int[2][MAX_TIME];

PFont labelFont;

void setup() {
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

//  for (int i=0; i<10; i++) simulator();

}

void drawgrid(){
  textFont(labelFont);
  stroke(128,128,128);
  for (int i=100; i<MAX_TEMP; i+=100) {
    text(str(i), 0, MAX_TEMP-i);
    line(0, MAX_TEMP-i, MAX_TIME, MAX_TEMP-i);
  }
  for (int i=1*60; i<MAX_TIME; i+=1*60) {
    text(str(i), i, MAX_TEMP);
    line(i, 0, i, MAX_TEMP);
  }
}

void drawchan(int [][] T, color c) {
  for (int i=1; i<idx; i++) {
    float x1 = T[0][i-1];
    float y1 = T[1][i-1];
    float x2 = T[0][i];
    float y2 = T[1][i];
    
    // sanity-check for noisy sensor data
    if (y1 > MAX_TEMP) y1 = MAX_TEMP;
    if (y2 > MAX_TEMP) y2 = MAX_TEMP;
    if (y1 < 0) y1 = 0;
    if (y2 < 0) y2 = 0;
    
    stroke(c);
    line(x1, MAX_TEMP-y1, x2, MAX_TEMP-y2);
  }
}

void draw() {
//  simulator();
  float sx = 1.;
  float sy = 1.;
  sx = float(width) / MAX_TIME;
  sy = float(height) / MAX_TEMP;
  scale(sx, sy);
  background(0);
  drawgrid();

  drawchan(T0, color(255,0,0) );  
  drawchan(T1, color(0,255,0) );  
  drawchan(T2, color(0,0,255) );
  drawchan(T3, color(255,204,0) );  
}

void serialEvent(Serial comport) {
  // grab a line of ascii text from the logger and sanity check it.
  String msg = comport.readStringUntil('\n');
  if (msg == null) return;
  msg = trim(msg);
  if (msg.length() == 0) return;

  // always store in file - good for debugging, version-tracking, etc.
  logfile.println(msg);

  if (msg.charAt(0) == '#') {
    println(msg);
    return;
  }
  
  String[] rec = split(msg, ",");
//  String[] rec = split(msg, "\t");
  if (rec.length != 6) {
    println("Ignoring unknown msg from logger: " + msg);
    return;
  }
  
  int timestamp = int(rec[0]);
  ambient[0][idx] = timestamp;
  ambient[1][idx] = int(rec[1]);
  T0[0][idx] = timestamp;
  T0[1][idx] = int(rec[2]);
  T1[0][idx] = timestamp;
  T1[1][idx] = int(rec[3]);
  T2[0][idx] = timestamp;
  T2[1][idx] = int(rec[4]);
  T3[0][idx] = timestamp;
  T3[1][idx] = int(rec[5]);
  

  for (int i=0; i<6; i++) {
    logfile.print(rec[i]);
    if (i < 5) logfile.print(",");
  }
  
  logfile.println();
  println(msg);
  
  idx++;
  idx = idx % MAX_TIME;
}

int zzz = 0;
void simulator() {
  T0[0][idx] = zzz;
  T0[1][idx] = zzz;
  zzz += 10;
  idx ++;
  idx = idx % MAX_TIME;
}

void stop() {
  comport.stop();
  logfile.flush();
  logfile.close();
  println("Data was written to: " + logfilename);
}





