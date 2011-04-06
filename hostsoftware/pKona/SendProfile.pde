int STEP_SIZE = 14;    //used for file checker, number of steps in the profile

int START_DATA_LINE = 3; //line number after start of profile indicator where data arrays start
int END_DATA_LINE = 11;  //line number after start of profile indicator where data arrays end

int NAME_LENGTH = 20;
int DATE_LENGTH = 16;


String infilename = " " ; //
int serial_ptr =0;
boolean wait_file = true;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port
int start_prof = 0;
boolean prof_found = false;
boolean once = true;
boolean file_ok;

// default values for port and baud rate
//String whichport = "COM4";
//int baudrate = 57600;
//color c0 = color(255,0,0); // channel 0
//color c1 = color(0,255,0);
//color c2 = color(255,255,0);
//color c3 = color(255,204,0);
//color cmin = color( 0,255,255 );
//color cidx = color( 0,255,255 );
//color clabel = color( 255,255,160 );
//int cbgnd = 80;  // background color

//PFont labelFont;

int cursor_x;
int cursor_y;

boolean clear_screen = false;

int screen_num = 1;

  String path = sketchPath;
  String tempstring;
  Boolean dofile = true;

//PID parameter variables
float Pb;
float I;
float D;
float PID_factor; 
int starttemp;
int maxtemp; 
int segment_0; 
int segment_1; 
int segment_2 ;
int seg0_bias;
int seg1_bias;
int seg2_bias; 
int seg0_min;
int seg1_min;
int seg2_min; 
int startheat;
int serial_type;
int roaster;

boolean done_sp = false;

//*********************************************************************************************************************

//ROUTINEs and FUNCTIONs

//*********************************************************************************************************************


// routine formats data from txt file to send to aKona, and sends data


void send_profile() {
  comport.write('a');  //send 'a' to tell aKona that a profile file is coming
  comport.write('^');  //send '^' to tell aKona that a command was sent

  check_file();    //routine that checks to make sure text file data is in correct format.
  if (file_ok == true) { //check to make sure that the file format is good before sending data
   
   //bunch of code to get time and date, and format it to send to aKona
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

     String lines_pf[] = loadStrings(infilename);   //load in the profile data from the input text file
     println("there are " + lines_pf.length + " lines");  //fyi
     //setup for loop to send out all lines in the input file
     for (int i=0; i < (lines_pf.length); i++) {		
      //println(lines_pf[i]);
       lines_pf[i] = trim (lines_pf[i]);  //trim spaces, tabs, cr, lf etc from current line
       if (lines_pf[i].length() != 0)  {   //check for 0 length lines
         if (lines_pf[i].charAt(0) != '/')  {   // a "/" indicates the line is a comment line,so ignore it.
           if (lines_pf[i].charAt(0) == '@') {    //@ at the start of a line indicates that this is the first line of a new profile
             print ("sending profile ");
             println (i);
             start_prof = i;  //set start of profile variable to the current line
             prof_found = true;  //set profile found flag
             comport.write('@');  //send start of profile flag out
             }			
           if (prof_found == true) {
             if (i == (start_prof + 1)) {    //check for first line in this profile, this line contains the profile name
               int k;
               for (k=0; k < lines_pf[i].length(); k++) {
                 comport.write(lines_pf[i].charAt(k));     // send the first line (profile name) to Kona, the name of the profile
                 }
               k++;  
               while (k<(NAME_LENGTH + 1)) {  //if name is less then name length chars long, send spaces until size is reached
                 comport.write(' ');//fill up rest of name with spaces
                 k++;
                 }
	//after the profile name, send the current time and date	
               comport.write(year_s[0]); 
               comport.write(year_s[1]);
               comport.write(year_s[2]);
               comport.write(year_s[3]);
               comport.write("/");
               comport.write(month_s[0]);
               comport.write(month_s[1]);
               comport.write("/");
               comport.write(day_s[0]);         
               comport.write(day_s[1]);         
	       comport.write(" ");
	       comport.write(hour_s[0]);
               comport.write(hour_s[1]);  
	       comport.write(":");
	       comport.write(minute_s[0]);
	       comport.write(minute_s[1]);
               }
             else if (i == (start_prof + 2)) {    //check for 2nd line, this line contains profile index number
               char index_s[] = {'0','0','0'}; 
               String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
//              comport.write(lines[0]);     // send the index number to Kona
//              comport.write(",");          //add comma seperator between numbers
              if (lines_pf[i].length() == 1) {
                index_s[2] = lines_pf[i].charAt(0);
                index_s[1] =  ('0');                     //if number is one digit, send leading 0, must send a two digit number
                index_s[0] =  ('0');                     //if number is one digit, send leading 0, must send a two digit number
                }
              else if (lines_pf[i].length() == 2) {
                index_s[2] = lines_pf[i].charAt(1);
                index_s[1] = lines_pf[i].charAt(0);                     //if number is one digit, send leading 0, must send a two digit number
                index_s[0] =  ('0');                     //if number is one digit, send leading 0, must send a two digit number
                }
              else {
                index_s[2] = lines_pf[i].charAt(2);
                index_s[1] = lines_pf[i].charAt(1);
                index_s[0] = lines_pf[i].charAt(0);
                }
              comport.write(index_s[0]);
              comport.write(index_s[1]);   
              comport.write(index_s[2]);   
              comport.write(",");          //add comma seperator between numbers              
              }

//now send the actual data lines, which are in lines 3-11
              else if ((i >= (start_prof + START_DATA_LINE)) && (i <= (start_prof + END_DATA_LINE))) { //check for 3rd through 11th lines
                //lines 3-11 are the data lines, containing ror, temp, time, offset, fanspeed, delta temp ,tbd1 ,tbd2, tbd3
                String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
                for (int k=0; k < STEP_SIZE; k++) {
                  comport.write(lines[k]);     // send the arrays to Kona
                  comport.write(",");          //add comma seperator between numbers
                  }
              }
//after data lines are sent, send last few lines
//first line after data rows end, contains max temp
              else if (i == (start_prof + END_DATA_LINE + 1 )) {
                String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
                comport.write(lines[0]);
                comport.write(",");          //add comma seperator between numbers
                }
//second line after data rows end, contains profile type
              else if (i == (start_prof + END_DATA_LINE + 2)) { 
                String[] lines = split(lines_pf[i], ",");  // comma separated input list, split this line into an array
                comport.write(lines[0]);
                comport.write(",");          //add comma seperator between numbers
                }
//third line after data rows end, contains end of profile or ene of file char
              else if (i == (start_prof + END_DATA_LINE + 3)) { 
                prof_found = false;  
                if (lines_pf[i].charAt(0) == '^') { 
                  comport.write("^");       //send end of transmission char
                  wait_file = true;     //reset flag, for next file.
                  //println ("Profile data was sent to Arduino");
                  }    
                else   {
                  comport.write("*");    //send end of profile char
                  comport.write(10);     //send line feed
                  comport.write(13);     //send carraige return
                  //println ("end prof");
                  delay (50);  //give some time for Kona to write profile to eeprom
                  } 
                }
              }    
            }	
          }	
       }// end for i	
    }  // end if check_file

} //end of send_profile routine



//*********************************************************************************************************************

// draw screen 01, which is the directory and select profile to send screen

void screen_01() {

 // size(700, 700);
  frameRate(2);
  smooth();
  background(cbgnd);

  fill( clabel );
  cursor_x=50;
  cursor_y =75;
  labelFont = createFont("Times New Roman", 20 );
  textFont( labelFont, 20 );
  text("Main Menu", cursor_x, cursor_y);


//this is where you write the current text input from the keyboard
  cursor_x=10;
  cursor_y +=60;
  text ("Type 's' to go to PID display edit screen", cursor_x, cursor_y );
  cursor_y +=30;
  text ("Type 'e' to edit a text profile file", cursor_x, cursor_y );
  cursor_y +=30;
  text ("Type 'p' to select profile file to send", cursor_x, cursor_y );
  cursor_y +=30;
  text ("Type 'r' to return to roast screen", cursor_x, cursor_y );
  cursor_y +=30;

   //infilename = new String(filename);
   //infilename = trim(infilename);  
 /*  for (int k=0; k < (serial_ptr); k++) {		
      char temp_char = filename[k];
      text (temp_char, cursor_x, cursor_y );
      cursor_x = cursor_x + 9;
      }

*/
  if (wait_file == false ) {   //wait until file name is entered.
     cursor_x=10;
     cursor_y =600;
     text ("Sending ", cursor_x, cursor_y );
     cursor_x += 80;

//   infilename = new String(filename);
//   infilename = trim(infilename);  
       text (infilename, cursor_x, cursor_y );

/*     for (int k=0; k < (serial_ptr); k++) {		
       char temp_char = filename[k];
       text (temp_char, cursor_x, cursor_y );
       cursor_x = cursor_x + 9;
        }
*/
        
     cursor_x=10;
     cursor_y =620;
     text (" to aKona ", cursor_x, cursor_y );
  }

}

//*********************************************************************************************************************
//draw screen 02, which is the PID parameter display and change screen

void screen_02() {

/*  //structure for storage of PID info in EEprom
struct PID_struc {
  int init_pattern;
 1 float Pb;  
 2 float I;  
 3 float D; 
 4 float PID_factor;
 5 int starttemp;
 6 int maxtemp;
 7 int segment_0;
 8 int segment_1;
 9 int segment_2;
 10 int seg0_bias;
 11 int seg1_bias;
 12 int seg2_bias;
 13 int seg0_min;
 14 int seg1_min;
 15 int seg2_min;
 16 int startheat;
 17 int serial_type;
 18 int roaster;

  };*/

  
  String screen02_string[] = {"1  Pb (FL)", "2  I (FL)", "3  D (FL)", "4  PID factor (FL)", "5  Start temp", "6  Max Temp", "7  Segment 0", "8  Segment 1", "9  Segment 2", "10 Seg 0 bias", 
  "11 Seg 1 bias", "12 Seg 2 bias",  "13 Seg 0 Min", "14 Seg 1 Min", "15 Seg 2 Min", "16 Starting heat", "17 Serial type                       (1=pKona, 2 = Artisan)",
  "18 Roaster                            (1=default, 2 = Alpenrost)" };
  
 // size(700, 700);
  frameRate(2);
//  smooth();
  background(cbgnd);
 
//  labelFont = createFont("Arial-Bold", 20 );
  labelFont = createFont("Times New Roman", 20 );
  fill( clabel );

  cursor_x=50;
  cursor_y =15;
  textFont( labelFont, 20 );
  text("PID Parameter Display and Change Screen ", cursor_x, cursor_y);
  
  cursor_x=10;
  cursor_y = 50;
  for (int k=0; k < 18; k++) {		//go write all the parameter names/numbers first
     text (screen02_string[k], cursor_x, cursor_y );
     cursor_y += 25;
     } 

  cursor_x = 175;
  cursor_y = 50;

  String parm_str = ""+Pb; //convert Pb to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+I; //convert I to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+D; //convert D to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+PID_factor; //convert D to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+starttemp; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+maxtemp; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+segment_0; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+segment_1; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+segment_2; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+seg0_bias; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+seg1_bias; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+seg2_bias; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+seg0_min; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+seg1_min; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+seg2_min; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+startheat; //convert start temp to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+serial_type; //convert serial type to string
  text (parm_str, cursor_x, cursor_y );
  cursor_y += 25;

  parm_str = ""+roaster; //convert roaster to string
  text (parm_str, cursor_x, cursor_y );

  cursor_x=10;
  cursor_y += 35;
  text("Enter Param no, then value.  Format is 'param number,value,ENTER' ", cursor_x, cursor_y);
  cursor_y += 30;
  text("Example, to change I to '1.1', type '2,1.1 ENTER'  ", cursor_x, cursor_y);
  cursor_y += 30;
  text("Note for floating point, ONLY one number after decimal point allowed ", cursor_x, cursor_y);
  cursor_y += 30;
  text("Press 'r' to return to first screen, or 'i' to reinit params ", cursor_x, cursor_y);
  cursor_y += 30;

if (serial_ptr > 0) {
   for (int k=0; k < (serial_ptr); k++) {		
      char temp_char = in_line_char[k];
      text (temp_char, cursor_x, cursor_y );
      cursor_x = cursor_x + 9;
      }
   }

}


//*********************************************************************************************************************
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
          if (lines_pf[i].length() > NAME_LENGTH) {
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
          if (lines.length > 2) {
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
  } //end for
}  //end of check file



