// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Contributor:  Randy Tsuchiyama
//
// THIS SOFTWARE IS PROVIDED BY THE CONTRIBUTOR "AS IS" AND ANY EXPRESS 
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ------------------------------------------------------------------------------------------

// serial.pde

/* send data to the serial (USB) port, for logging and display on a PC
 This program is based on 
 pBourbon.pde and 16 x 2 LCD
 by Jim Gallt and Bill Welch

*/

//note that the strings are stored in program memory to save ram
prog_char prt_string_00[] PROGMEM = "# profile is        ";   // "prt_string 00" etc are strings used for lcd display.
prog_char prt_string_01[] PROGMEM = "# roast method is (1";
prog_char prt_string_02[] PROGMEM = "=TimeTemp 2=Auto ROR";
prog_char prt_string_03[] PROGMEM = "3= Manual ROR):     ";
prog_char prt_string_04[] PROGMEM = "# Time,Ambient,MT,RO"; 
prog_char prt_string_05[] PROGMEM = "R MT,CT,ROR CT,Setpo";
prog_char prt_string_06[] PROGMEM = "int,Step,Step Timer,";
prog_char prt_string_07[] PROGMEM = "Heat,Fanspeed,ROR,De";
prog_char prt_string_000[] PROGMEM = "";
prog_char prt_string_001[] PROGMEM = "";
prog_char prt_string_10[] PROGMEM = "# Max temp is:    ";
prog_char prt_string_11[] PROGMEM = "lta T(sp-ct)";
prog_char prt_string_12[] PROGMEM = "#End roast";
prog_char prt_string_13[] PROGMEM = ",";
// Then set up a table to refer to your strings.

PROGMEM const char *prt_string_table[] = 	   // change "prt_string_table" name to suit
{   
  prt_string_00,
  prt_string_01,
  prt_string_02,
  prt_string_03,
  prt_string_04,
  prt_string_05, 
  prt_string_06, 
  prt_string_07, 
  prt_string_000, 
  prt_string_001,
  prt_string_10,
  prt_string_11,
  prt_string_12,
  prt_string_13
};


// ------------------------------------------------------------------------
// this routine sends data to the serial port during the roast
 
void serial_send_data()
{
int i;

  Serial.print(tod, DP);    //1  = time

// print ambient
//  Serial.print(",");
  strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[13]))); // Necessary casts and dereferencing
  Serial.print( char_buf);
  Serial.print( t_amb, DP );  //2 = amb temp
  
//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( mt, DP );    //3 = monitor temp
//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( RoRmt, DP );  //4 = mt ror
   
//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( ct, DP );   //5= control temp
//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( RoRct, DP );  //6= ror ct

  //send setpoint to logfile
//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( setpoint, DP );  //send setpoint, to compare setpoint to temps
  
//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( step );  //send step number

//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( step_timer );  //send step timer 

//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( heat, DP );

  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print( FanSpeed);

//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print( ROR, DP );

  Serial.println();


  }

// ------------------------------------------------------------------------
// this routine sends data to the serial port during the roast
 
void serial_send_header()
{
int i;

// send name of profile selected to log file
//Serial.print("# profile is ");   //prt_string_00
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[00]))); // Necessary casts and dereferencing
Serial.print( char_buf);

for (i = 0; i < 16; i++) {   //send name of this profile to display
	Serial.print(myprofile.name[i]);
	}
Serial.println();

// send roast method to log file

strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[01]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("# roast method is (1=");     //prt_string_01
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[02]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("TimeTemp 2=Auto ROR  ");    //prt_string_02
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[03]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("3=Manual ROR):       ");    //prt_string_03
Serial.print(roast_method);
Serial.println();

// send max temp to log file
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[10]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("# Max temp is:    ");
Serial.print(max_temp);
Serial.println();

//send header information to log file
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[04]))); // Necessary casts and dereferencing
Serial.print( char_buf);

//Serial.print("# Time,Ambient,MT,RO");
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[05]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("R MT,CT,ROR CT,Setpo");
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[06]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("int,Step,Step Timer,");
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[07]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("Heat,Fanspeed,ROR,De");
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[11]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("lta T(sp-ct)");
Serial.println();

 
}


// ------------------------------------------------------------------------
// this routine sends the end of roast message to the serial port
 
void serial_send_end()
{

// send end of roast message
strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[12]))); // Necessary casts and dereferencing
Serial.print( char_buf);
//Serial.print("#End roast");
Serial.println(); 
}

// ------------------------------------------------------------------------
// this routine sends the message to start the profile download
 
void serial_send_start_dl() {
// send start of profile download message
Serial.print("#go");
Serial.println();
}



// ------------------------------------------------------------------------
// this routine reads a command on the serial port, sent from a PC
//it stores the PC serial data in a string

void serial_read()
{
//Global variables used here
// int serial_in_cnt = 0;  //counter for serial input data
// byte serial_in_line[10];  //input line array, 
// boolean serial_command_rx;
// int serial_command;

if (Serial.available() > 0) {  //check to see if anything was received
   serial_in_line[serial_in_cnt]  = Serial.read();    //if something is there, go read it

   if (serial_in_line[serial_in_cnt] == '^') {  //look for end of transmission char
      serial_command_rx = true;
      serial_in_cnt = 0;
      }
   else {
      serial_in_cnt++;   }
   }
}

// ------------------------------------------------------------------------

void send_PID() {
  Serial.print(  myPID.Pb,DP );
  //Serial.print(",");
  strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[13]))); // Necessary casts and dereferencing
  Serial.print( char_buf);
  Serial.print(  myPID.I, DP);  
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.D, DP); 
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.PID_factor);
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.starttemp );
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.maxtemp );
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.segment_0);
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.segment_1);
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.segment_2);
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.seg0_bias);
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.seg1_bias);
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.seg2_bias);
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.seg0_min );
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.seg1_min );
  //Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.seg2_min );
//  Serial.print(",");
  Serial.print( char_buf);
  Serial.print(  myPID.startheat );

  Serial.print( char_buf);
  Serial.print(  myPID.serial_type );

  Serial.print( char_buf);
  Serial.print(  myPID.roaster );
  Serial.println();  

} 


// ------------------------------------------------------------------------

void serial_read_art()

{

//char cmd0;
//char cmd1;
//char arg0;
//char arg1;
//char arg2;
//char arg3; 

// protocol is "CCaaaa", two bytes of command, four bytes of args
if( Serial.available() >= 6 ) { // command length is 6 bytes
   for (serial_in_cnt=0; serial_in_cnt<6; serial_in_cnt++) {
      serial_in_line[serial_in_cnt]  = Serial.read();    //if something is there, go read it
      }
   }

if (serial_in_line[0] == 'R') {  //check for a read command
   send_art(); // output results to serial port
   }
else if ((serial_in_line[0] == 'A') || (serial_in_line[0] == 'a')) {  //check for a set ROR command
   serial_in_line[6]  = ('^');    //setup the end of number indicator for convert_int function call
   byte_ptr = &serial_in_line[2];       //set pointer to arg0
   temp_int = (convert_int());    //  convert_int is a function that converts a string to an int
   ROR = temp_int;  
   delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
   step_timer = 0;  //reset step timer when ROR/slope is changed
   }
else if ((serial_in_line[0] == 'T') || (serial_in_line[0] == 't')) {  //check for a set temp command
   serial_in_line[6]  = ('^');    //setup the end of number indicator for convert_int function call
   byte_ptr = &serial_in_line[2];       //set pointer to arg0
   temp_int = (convert_int());    //  convert_int is a function that converts a string to an int
   target_temp = temp_int;        //set new target temp
   if (roast_method == AUTO_TEMP) {  //check to see if this is in an temp/time profile
      delta_temp =  (target_temp - setpoint);  //change end temp for this ramp by adjusting slope used in setpoint calcs
      delta_t_per_sec =  (delta_temp / step_timer); //
      }
   }//end if 'T'
}  //end serial_read_art function


// ------------------------------------------------------------------------
void send_art () {

  strcpy_P(char_buf, (char*)pgm_read_word(&(prt_string_table[13]))); // Necessary casts and dereferencing to print a ,

  Serial.print(t_amb, DP );

// print temperature, rate for each channel
  Serial.print( char_buf);
  Serial.print( mt, DP );    //send monitor temp (bt)
  Serial.print( char_buf);
  Serial.print( ct, DP );  //send control temp ( environmental temp)

  Serial.print("\n");


}
