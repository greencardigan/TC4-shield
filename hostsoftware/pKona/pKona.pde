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
String appname = "Kona PID Roast Logger v3.00";

String cfgfilename = "pKona.cfg"; // whichport, baudrate

String in_line_string ; //
char in_line_char[] = {' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '};
int in_line_ptr=0;
boolean send_command = false;


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
float fanspeed = 0;
float ror = 0;

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

  screen_num = 0;

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

// ------------------------- write data values at top of screen
//inclding time, ct, mt, mtror, setpoint, counter, step number, ror (commanded)

void monitor( int t1, int t2 ) {
  int minutes,seconds;
  
	if( idx > 0 ) {
		String strng;
    float w;
    int iwidth = width;    //from above "size(1200, 800);", so width is 1200
    int incr = iwidth / 10;  
    int pos = incr;

  labelFont = createFont("Tahoma-Bold", 16 );
  
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

//write count timer.  Counts up in ROR moded, down in time/temp mode
    pos += incr;
    fill(clabel);	
    //fill( c1 );
    strng = nf( countdown,3,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,16);            //text (data, x posn, y posn)
    strng = "Counter";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,32 );

//write delta temp, delta between setpoint and ct
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

//write ROR
    pos += incr;
    fill(clabel);	
    strng = nf( ror,3,0 );
    w = textWidth(strng);
    textFont( labelFont, t1 );
    text(strng,pos-w,64);            //text (data, x posn, y posn)
    strng = " ROR";
    textFont( labelFont, t2 );
    w = textWidth( strng );
    text(strng,pos-w,80 );
	
  }
}

// ------------------------------------------------------
void screen_00() {  //screen 0 is the screen which displays the roast graph and roast data during the roast
//  size(1200, 800);
//  frameRate(1);
//  smooth();
//  background(cbgnd);

  float sx = 1.;
  float sy = 1.;
  sx = float(width) / MAX_TIME;
  sy = float(height) / ( MAX_TEMP - MIN_TEMP );
  scale(sx, sy);
  background( cbgnd );

  drawgrid();
  drawchan(T0, c0 );  
  drawchan(T1, c1 ); 
  if( NCHAN >= 2 )   drawchan(T2, c2 );
     monitor( 18, 16 );
  }


// ------------------------------------------------------
void draw() {
 // float sx = 1.;
 // float sy = 1.;
 // sx = float(width) / MAX_TIME;
 // sy = float(height) / ( MAX_TEMP - MIN_TEMP );
 // scale(sx, sy);
//  size(1200, 800);
//  frameRate(1);
//  smooth();
  background(cbgnd);

  if( !started ) {
    labelFont = createFont("Tahoma-Bold", 20 );
    textFont( labelFont );
    text( appname + "\nPress a key or click to begin Arduino program ...\n",110, 110 );
    text( "\nPress 'k' to send profiles or read and change the PID/eeprom parameters\n",110, 150 );
    }
  else {
     if ( screen_num == 0 )  { //default screen, displays graph during the roast
        screen_00();  }
     if ( screen_num == 1 )  { //goes to this screen if you push 'k' at startup, lets you send a profile or change the PID (eeprom) parameters
        screen_01();  }        //routine in SendProflie module
        if (wait_file == false ) {   //wait until file name is entered.
           send_profile();      //routine in SendProflie module
           } //end if wait_file
     if ( screen_num == 2 )  {
        screen_02();  }         //routine in SendProflie module
     };
  }

// -------------------------------------------------------------
void serialEvent(Serial comport) {    //reads data from serial port
  // grab a line of ascii text from the logger and sanity check it.
  String msg = comport.readStringUntil('\n');
  if (msg == null) return;
  msg = trim(msg);               //trim spaces, tabs, cr, lf etc from msg
  if (msg.length() == 0) return;

  // always store in file - good for debugging, version-tracking, etc.
  //logfile.println(msg);

	//end of roast message from Kona is "#End roast"
   if ((msg.charAt(0) == '#') && (msg.charAt(0) == 'E')) {   //check for end of roast
      logfile.println(msg);
   println(msg);
   saveFrame(filename + "-##" + ".jpg" );
   return;
   }
   
   if ((msg.charAt(0) == '#') && (msg.charAt(1) == 'g') && (msg.charAt(2) == 'o')) {   //check for #go
     //println ("Kona ready"); 
     once = false;  //set flag to send data to Kona
     return;
     }


  if (msg.charAt(0) == '#') {   //check if debug message
    logfile.println(msg);
    println(msg);
    return;
  }
  
  String[] rec = split(msg, ",");  // comma separated input list, split msg into an array


  if ( screen_num == 0 )  {

/* rec[0]=time,  rec[1]=ambient temp, rec[2]=tmp ch1(mt),  rec[3]=ror 1,  rec[4]=tmp ch 2(ct), rec[5]=ror 2,
   rec[6]=setpoint, rec[7]=step number, rec[8]=countdown timer, rec[9]=heat, rec[10]=fanspeed, rec[11]=ROR
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
  
     ror = float (rec[11]);

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
     idx = idx % BUFFER_SIZE;  //keep idx from overflowing
     } // end if screen num = 00
     
  else if ( screen_num == 2 )  {
    
/* rec[0]=Pb,  rec[1]=I, rec[2]=D,  rec[3]=PID_factor,  rec[4]=start temp, rec[5]=max temp, rec[6]=segment 0, 
   rec[7]=segment 1, rec[8]=segment 2, rec[9]=seg0 bias, rec[10]=seg1 bias, rec[11]=seg2 bias, rec[12]=seg0 min
   rec[13]=seg1 min, rec[14]=seg2 min, rec[15]=start heat
*/

  Pb = float(rec[0]);
  I  = float(rec[1]);
  D  = float(rec[2]); 
  PID_factor = float(rec[3]);
  starttemp = int(rec[4]);  
  maxtemp = int(rec[5]);  
  segment_0 = int (rec[6]);
  segment_1 = int (rec[7]);
  segment_2 = int (rec[8]);
  seg0_bias = int (rec[9]);
  seg1_bias = int (rec[10]);
  seg2_bias = int (rec[11]);
  seg0_min = int (rec[12]);
  seg1_min = int (rec[13]);
  seg2_min = int (rec[14]);
  startheat = int (rec[15]);
  serial_type = int (rec[16]);
  roaster  = int (rec[17]);

  }//end if screen num = 02
     
  }
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
void keyPressed()          //reads the keyboard data
{ 
  if( !started )  {  //check to see if program has started yet
    char key_char = key;
    if ((key == 'k') || (key == 'K')) {  //see if k was pushed
       screen_num = 1; 
       serial_ptr = 0;
       in_line_ptr=0;
       }
    startSerial();
    }
  else {       //program is now running, go get the kb input
//    print(key);
  char key_char = key;
  if ( screen_num == 0 )  {
    if (keyCode == 10)  { //check for CR, if CR then process the line
      if ((in_line_char[0]== 'r') ||  (in_line_char[0]== 'R')) {
          in_line_char[in_line_ptr++]= '^';  }       //add termination char to end of line 
      in_line_string = new String(in_line_char);  //convert to a string
      in_line_string = trim(in_line_string);  //trim out spaces and other junk
      String[]text_in = split(in_line_string, ",");  // comma separated input list, split in_line_string into an array
      comport.write(text_in [0]);          //send out first char (command)
      comport.write(',');          //send out comma (don't care about this char
      comport.write('0');          //send out first char of 4 digit number, always a zero
      println ("sent r command");

      if (text_in[1].length() == 1) {
        comport.write('0');          //send out 2nd char of 4 digit number
        comport.write('0');          //send out 3rd char of 4 digit number
        comport.write(text_in[1]);          //send out fourth char of 4 digit number
        }

      if (text_in[1].length() == 2) {
        comport.write('0');          //send out 2nd char of 4 digit number
        comport.write(text_in[1]);          //send out 3rd and fourth char of 4 digit number
        }
      else {
        comport.write(text_in[1]);    }      //send out 2nd, 3rd and fourth char of 4 digit number
//      comport.write(in_line_string);          //send out line now

      in_line_ptr = 0;                        //reset pointer for next line
      send_command = true;
      }  //end if CR
    else {   //if not CR,then just read in the char
      in_line_char[in_line_ptr++]= key_char; // 
      }
    }  
 else if ( screen_num == 1 )  {
     if ((key == 'p') || (key == 'P') || (keyCode == 10))  { //check for CR
        infilename = selectInput("choose File");  // Opens file chooser, set infilename to file picked
        if (infilename == null) {
         // If a file was not selected
           println("No file was selected...");
           } 
        else {
         // If a file was selected, print path to file
           println ("");
           println(infilename);
           wait_file = false;     //set flag to notify that file was selected
           serial_ptr = 0;
           }

       }  //end if CR
     else if ((key == 's') || (key == 'S')) {  //see if p was pushed
     //SEARCH
       comport.write('b');  //send 'b' to tell aKona that a send PID parameters
       comport.write('^');  //send '^' to tell aKona that a command was sent
       screen_num = 2;  // this is command to go to screen 2 (display and change PID parameters)
       serial_ptr = 0;
     } //end if 'p'

     else if ((key == 'e') || (key == 'E')) {  //see if e was pushed
       infilename = selectInput("choose File to Edit");  // Opens file chooser, set infilename to file picked
       String prog_name[] ={"notepad", infilename}; 
       println (prog_name);
       open (prog_name);
       serial_ptr = 0;
     } //end if 'e'
   
     else if ((key == 'r') || (key == 'R')) {  //see if k was pushed
       screen_num = 0; 
       serial_ptr = 0;
       }

   }  //end if screen_num == 1
   
   else if ( screen_num == 2 )  {
    if (keyCode == 10)  { //check for CR, if CR then process the line
      in_line_char[serial_ptr++]= '^';         //add termination char to end of line 
      in_line_string = new String(in_line_char);  //convert to a string
      in_line_string = trim(in_line_string);  //trim out spaces and other junk
//      println(in_line_string);
     //SEARCH
      comport.write('p');  //send 'p' to tell aKona to program a PID parameter
      comport.write(in_line_string);          //send out line now
      comport.write('^');  //send '^' to tell aKona that a command was sent
      serial_ptr = 0;                        //reset pointer for next line
      delay (500);  //give aKona time to write the parameters
      comport.write('b');  //send 'b' to tell aKona that a send PID parameters
      comport.write('^');  //send '^' to tell aKona that a command was sent
      //send_command = true;
      }  //end if CR
    else {   //if not CR,then just read in the char
        if ((key == 'r') || (key == 'R')) {  //see if ^r was pushed
          screen_num = 1; 
          serial_ptr = 0;
          }
        if ((key == 'i') || (key == 'I')) {  //see if i was pushed.  If it was pushed, sent init PID command to aKona
     //SEARCH
         comport.write('i');  //send 'i' to tell aKona to reinit the PID parameters
         comport.write('^');  //send '^' to tell aKona that a command was sent
         serial_ptr = 0;                        //reset pointer for next line
         delay (500);  //give aKona time to write the parameters
         comport.write('b');  //send 'b' to tell aKona that a send PID parameters
         comport.write('^');  //send '^' to tell aKona that a command was sent
         //send_command = true;
          }
       else if ((key == BACKSPACE) && (serial_ptr > 0)) {
          serial_ptr--;  //if backspace, delete last character
          clear_screen = true;
          }
       else {
         in_line_char[serial_ptr++]= key_char; // 
      }
    } //end else
  }//end if screen_num == 2
   
  
 }
} //end keypressed


// ------------------------------------------
void startSerial() {
  started = true;

  textFont( labelFont );
  text( appname + "\nPress a key or click to begin logging ..." 
    + "\nOpening serial port (this may take several seconds) ...",300, 110 );

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


