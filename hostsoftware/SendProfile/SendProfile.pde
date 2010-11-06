import processing.serial.*;
Serial comport;

int STEP_SIZE = 14;    //used for file checker, number of steps in the profile

int START_LINE = 3; //line number after start of profile indicator where data arrays start
int END_LINE = 11;  //line number after start of profile indicator where data arrays end

String cfgfilename = "SendProfile.cfg"; // whichport, baudrate
//String infilename ; // 
//char infilename[];// ="profile.txt"; // 

//String infilename ="profile.txt"; //
String infilename ; //
char filename[] = {' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '};
char defaultfile[] = {'p','r','o','f','i','l','e','.','t','x','t'};
int filename_ptr =0;
boolean wait_file = true;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port
int start_prof = 0;
boolean prof_found = false;
boolean once = true;
boolean file_ok;

// default values for port and baud rate
String whichport = "COM4";
int baudrate = 57600;
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


void setup() 
{
  size(200, 200);
    // read com port settings from config file
  // format is: value, comment/n
  String[] lines_cf = loadStrings( cfgfilename );
  if( lines_cf.length >= 1 ) {
    String[] portstring = split( lines_cf[0], "," );
    whichport = portstring[0];
  };
  if( lines_cf.length >= 2 ) {
      String[] baudstring = split( lines_cf[1], "," );
      baudrate = int( baudstring[0] );
      };
  comport = new Serial(this, whichport, baudrate);
  println( whichport + " comport opened.");
  comport.clear();

  print( "COM Port: "); println( whichport );
  print( "Baudrate: "); println( baudrate );
  
  println( "Enter text filename now, without '.txt' ");
  println( "Or push 'ENTER' for default 'profile.txt' file name");
  //infilename = new String(defaultfile);
//  println ( filename ) ; //     
//  println ( infilename ) ; // 
}  //end of setup

void draw() {
 
  if (wait_file == false ) {   //wait until file name is entered.
//    println ("got file");
//    println ( infilename ) ; // 
//    println ( filename ) ; //     

  
if (once == false) { //only send data once
  once = true;
  wait_file = true;
  	
  check_file();
  if (file_ok == true) { //check to make sure that the file format is good before sending data
  
    //get time and date
    int d = day();    // Values from 1 - 31
    int mo = month();  // Values from 1 - 12
    int y = year();   // 2003, 2004, 2005, etc.
    int s = second();  // Values from 0 - 59
    int mi = minute();  // Values from 0 - 59
    int h = hour();    // Values from 0 - 23
    //init arrays
    String ds = String.valueOf(d);
    ds = trim (ds);
    String mos = String.valueOf(mo);
    mos = trim (mos);
    String hs = String.valueOf(h);
    hs = trim (hs);
    String mis = String.valueOf(mi);
    mis = trim (mis);
    char day_s[] = {'0','0'};
    char month_s[] = {'0','0'};
    char year_s[] = {'0','0','0','0'};
    char hour_s[] = {'0','0'};
    char minute_s[] = {'0','0'}; 
  
  
    
    if (ds.length() == 1) {
      day_s[1] = ds.charAt (0);
      day_s[0] = ('0');
      }
    else {
      day_s[1] = ds.charAt (1);
      day_s[0] = ds.charAt (0);
      }

    if (mos.length() == 1) {
      month_s[1] = mos.charAt (0);
      month_s[0] = ('0');
      }
    else {
      month_s[1] = mos.charAt (1);
      month_s[0] = mos.charAt (0);
      }

    year_s[0] = String.valueOf(y).charAt(0);
    year_s[1] = String.valueOf(y).charAt(1);
    year_s[2] = String.valueOf(y).charAt(2);
    year_s[3] = String.valueOf(y).charAt(3);

    if (hs.length() == 1) {
      hour_s[0] = ('0');
      hour_s[1] = hs.charAt (0);
      }
    else {
      hour_s[1] = hs.charAt (1);
      hour_s[0] = hs.charAt (0);
      }

    if (mis.length() == 1) {
      minute_s[0] = ('0');
      minute_s[1] = mis.charAt (0);
      }
    else {
      minute_s[1] = mis.charAt (1);
      minute_s[0] = mis.charAt (0);
      }

    String lines_pf[] = loadStrings(infilename);   //load in the profile data
    println("there are " + lines_pf.length + " lines");  //fyi
    //for (int i=0; i < (lines_pf.length-1); i++) {
    for (int i=0; i < (lines_pf.length); i++) {		
      println(lines_pf[i]);
      lines_pf[i] = trim (lines_pf[i]);  //trim spaces, tabs, cr, lf etc from msg
      if (lines_pf[i].length() != 0)  {   //check for 0 length lines
        if (lines_pf[i].charAt(0) != '/')  {   // a "/" indicates the line is a comment line,so ignore it.
          if (lines_pf[i].charAt(0) == '@') {    //@ at the start of a line indicates that this is the start of a profile
            print ("start profile at line: ");
            println (i);
            start_prof = i;
            prof_found = true;
            comport.write('@');
            }			
          if (prof_found == true) {
            if (i == (start_prof + 1)) {    //check for first line in this profile
              char index_s[] = {'0','0'}; 
              String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
              if (lines_pf[i].length() == 1) {
                index_s[0] =  ('0');  
                index_s[1] = lines_pf[i].charAt(0);}
              else {
                index_s[1] = lines_pf[i].charAt(1);
                index_s[0] = lines_pf[i].charAt(0);
                }
              comport.write(index_s[0]);
              comport.write(index_s[1]);
                //println (index_s);
              }
            else if (i == (start_prof + 2)) {    //check for 2nd line, contains profile name
              int k;
              for (k=0; k < lines_pf[i].length(); k++) {
                comport.write(lines_pf[i].charAt(k));     // send the first line (profile name) to Kona, the name of the profile
                }
              k++;  
              while (k<17) {
                comport.write(' ');//fill up rest of name with spaces
                k++;
                }
	//after the profile name, send the current time and date	
              comport.write(year_s[0]); 
              comport.write(year_s[1]);
              comport.write(year_s[2]);
              comport.write(year_s[3]);
              comport.write("/");
							//println (year_s);
							comport.write(month_s[0]);
							comport.write(month_s[1]);
							comport.write("/");
							//println (month_s);
							comport.write(day_s[0]);         
							comport.write(day_s[1]);         
							comport.write(" ");
							//println (day_s);
							comport.write(hour_s[0]);
							comport.write(hour_s[1]);  
							comport.write(":");
							//println (hour_s);
							comport.write(minute_s[0]);
							comport.write(minute_s[1]);
							//println (minute_s);
		}
              else if ((i >= (start_prof + START_LINE)) && (i <= (start_prof + END_LINE))) { //check for 3rd through 11th lines
                String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
                for (int k=0; k < STEP_SIZE; k++) {
                  //println (lines [k]);
                  comport.write(lines[k]);     // send the arrays to Kona
                  comport.write(",");          //add comma seperator between numbers
									}
								}
              else if (i == (start_prof + END_LINE +1)) {
                String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
								comport.write(lines[0]);
								//println (lines [0]);
								}
              else if (i == (start_prof + END_LINE + 2)) {
                String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
								comport.write(lines[0]);
								//println (lines [0]);
								}
								else if (i == (start_prof + END_LINE + 3)) {
                prof_found = false;  
                if (lines_pf[i].charAt(0) == '^') { 
                  comport.write(",^");       //send end of transmission char
                  println ("Profile data was sent to Arduino");
                  }    
                else   {
                  comport.write(",*");    //send end of profile char
                  comport.write(10);     //send line feed
		  comport.write(13);     //send carraige return
                  println ("end prof");
                  delay (50);  //give some time for Kona to write profile to eeprom
                  } 
                }
              }    
            }	
          }	
        }// end for i	
      }  // end if check_file
  } //end once == false
} //end if wait_file

  background(255);
    size(1200, 800);
  frameRate(1);
  smooth();
  background(cbgnd);

//  comport.write('L');              // send an L otherwise

//  rect(50, 50, 200, 200);         // Draw a square
}

void del() { // Test if mouse is over square
  delay (10000);
}

// ------------------------------- send data when mouse is clicked
void mouseClicked() {
  if( once == true ) {
    once = false;   //set flag to send data to Kona
  }
}

// ------------------------------- read keyboard and input text file name

void keyPressed() {
  print(key);
//  int get_key = keyCode;
  char key_char = key;
  if (keyCode == 10)  { //check for CR
    if (filename_ptr==0) {
      infilename = new String(defaultfile);
      infilename = trim(infilename);  
      }
    else {
      filename[filename_ptr++]= ('.'); // 
      filename[filename_ptr++]= ('t'); // 
      filename[filename_ptr++]= ('x'); // 
      filename[filename_ptr++]= ('t'); // 
      infilename = new String(filename);
      infilename = trim(infilename);  
      }
    wait_file = false;     //if cr, then finished reading in file name
    print (infilename);
    println(" will be transmitted to Arduino");     
    println();     
    println("Now on the Arduino side, go to 'Profile' then select 'Profile Receive' ");     
    }  //end if CR
  else {
    filename[filename_ptr++]= key_char; // 
    }

//  sprintf( smin, "%02u", itod / 60 );
//  strcpy( LCD01, smin );
//  strcat( LCD01, ":" );


//  println(key_char);  
}

//void keyTyped() 

// -------------------------------------------------------------
void serialEvent(Serial comport) {
  // grab a line of ascii text from serial port and check for ready to send message from Kona
  String msg = comport.readStringUntil('\n');
  if (msg == null) return;
  msg = trim(msg);               //trim spaces, tabs, cr, lf etc from msg
  if (msg.length() == 0) return;

  println(msg);

  if ((msg.charAt(0) == '#') && (msg.charAt(1) == 'g') && (msg.charAt(2) == 'o')) {   //check for #go
    println ("Kona ready"); 
    once = false;  //set flag to send data to Kona
    return;
  }
  
  } // serialEvent

// -------------------------------------------------------------
// check the integrity of the data in the profile text file before sending the data
void check_file()  {
int prof_cnt = 0;
float ind;

file_ok=true;

String lines_pf[] = loadStrings(infilename);   //load in the profile data
//String lines_pf[] = loadStrings("profile.txt");   //load in the profile data
println("there are " + lines_pf.length + " lines");  //fyi
for (int i=0; i < (lines_pf.length-1); i++) {
  lines_pf[i] = trim (lines_pf[i]);  //trim spaces, tabs, cr, lf etc from msg
  if (lines_pf[i].length() == 0)  {
    print ("found blank line, at line number");
    println (i);
    println ("please fix");
    file_ok = false;
    }
  if (lines_pf[i].length() != 0)  {
    if (lines_pf[i].charAt(0) != '/')  {   // a "/" indicates the line is a comment line,so ignore it.
      if (lines_pf[i].charAt(0) == '@') {    //@ at the start of a line indicates that this is the start of a profile
        start_prof = i;
        prof_found = true;
        prof_cnt++;
        }			
      if (prof_found == true) {
        if (i == (start_prof + 1)) {    //check for first line in this profile
          String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
          ind = float(lines[0]);
          if ((ind < 0.0) || (ind > 100.0)) {
            print ("index is ");
            println (ind);
            print ("index out of range for profile ");
            println (prof_cnt);
            file_ok = false;
            }
          }
        else if (i == (start_prof + 2)) {    //check for 2nd line, contains profile name
          if (lines_pf[i].length() > 16) {
            print ("Profile name is too long, length is ");
            println (lines_pf[i].length());
            print ("For profile ");
            println (prof_cnt);
            file_ok = false;
            }
          if (lines_pf[i].length() == 0) {
            println ("Profile name is 0 length");
            print ("For profile ");
            println (prof_cnt);
            file_ok = false;
            }
          }
        else if ((i > (start_prof + 2)) && (i < (start_prof + 12))) { //check for 3rd through 12th lines
          String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
          if (lines.length < STEP_SIZE) {
            print ("This row is too short, it's length is ");
            println (lines.length);
            print ("For profile ");
            println (prof_cnt);
            print ("line number ");
            println (i);
            file_ok = false;
            }
          if (lines.length > STEP_SIZE) {
            print ("This row is too long, it's length is ");
            println (lines.length);
            print ("For profile ");
            println (prof_cnt);
            print ("line number ");
            println (i);
            file_ok = false;
            }
					}
        else if (i == (start_prof + 12)) {
          String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
	 //println (lines [0]);
          if (lines.length == 0) {
            print ("This row is too short, it's length is ");
            println (lines.length);
            print ("For profile ");
            println (prof_cnt);
            print ("line number ");
            println (i);
            file_ok = false;
            }
          if (lines.length > 1) {
            print ("This row is too long, it's length is ");
            println (lines.length);
            print ("For profile ");
            println (prof_cnt);
            print ("line number ");
            println (i);
            file_ok = false;
            }
          }
				else if (i == (start_prof + 14)) {
					prof_found = false;  
					if ((lines_pf[i].charAt(0) != '^') && (lines_pf[i].charAt(0) != '*')) {   
						println ("No end of profile or end of file marker found ");
						print ("For profile ");
						println (prof_cnt);
						print ("line number ");
						println (i);
						file_ok = false;
						}
  
          } 
        }
      }  //if profile=true	
    }   	
	}
}

if ( file_ok == false) {
   println ("file ok is false");
   }

}


