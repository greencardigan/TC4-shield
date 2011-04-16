import processing.core.*; 
import processing.xml.*; 

import processing.serial.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class pCOMlist extends PApplet {

// program lists the COM ports on the machine

// Author:  Jim Gallt 20100705
// adapted from code written by Bill Welch


Serial comport;
String[] portlist;
PFont listfont;
String portstrings;


public void setup() {
  portstrings = "Available COM ports:\n";
  portlist = Serial.list();
  println( portlist );
  for( int i = 0; i < portlist.length; i++ ) {
    portstrings += portlist[i] + "\n";
  };
  size( 200,400 );
  frameRate( 1 );
  smooth();
  background( 100 );
  fill( 255 );
  listfont = createFont("Tahoma-Bold",16);
  textLeading( 5 );
  textFont( listfont );
}

public void draw() {
  text( portstrings, 5, 20, 400, 400 );
}


  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#ECE9D8", "pCOMlist" });
  }
}
