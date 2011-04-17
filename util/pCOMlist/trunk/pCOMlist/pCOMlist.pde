// program lists the COM ports on the machine

// Author:  Jim Gallt 20100705
// adapted from code written by Bill Welch

import processing.serial.*;
Serial comport;
String[] portlist;
PFont listfont;
String portstrings;

void setup() {
  portstrings = "Available COM ports:\n";
  portlist = Serial.list();
  println( portlist );
  for( int i = 0; i < portlist.length; i++ ) {
    portstrings += portlist[i] + "\n";
  };
  size( 400,400 );
  frameRate( 1 );
  smooth();
  background( 100 );
  fill( 255 );
  listfont = createFont("Tahoma-Bold",16);
  textLeading( 5 );
  textFont( listfont );
}

void draw() {
  text( portstrings, 5, 20, 400, 400 );
}


