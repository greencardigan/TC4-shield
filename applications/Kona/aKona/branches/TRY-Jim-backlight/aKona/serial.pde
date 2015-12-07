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
  prt_string_12
};


// ------------------------------------------------------------------------
// this routine sends data to the serial port during the roast
 
void serial_send_data()
{
int i;

  Serial.print(tod, DP);    //1  = time

// print ambient
  Serial.print(",");
  Serial.print( t_amb, DP );  //2 = amb temp
  
  Serial.print(",");
  Serial.print( mt, DP );    //3 = monitor temp
  Serial.print(",");
  Serial.print( RoRmt, DP );  //4 = mt ror
   
  Serial.print(",");
  Serial.print( ct, DP );   //5= control temp
  Serial.print(",");
  Serial.print( RoRct, DP );  //6= ror ct

  //send setpoint to logfile
  Serial.print(",");
  Serial.print( setpoint, DP );  //send setpoint, to compare setpoint to temps
  
  Serial.print(",");
  Serial.print( step );  //send step number

  Serial.print(",");
  Serial.print( step_timer );  //send step timer 

  Serial.print(",");
  Serial.print( heat, DP );

  Serial.print(",");
  Serial.print( FanSpeed);

  Serial.print(",");
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

//Serial.print(myprofile.profile_method);
//Serial.println();

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
 
void serial_send_start_dl()
{

// send start of profile download message
Serial.print("#go");
Serial.println();
}



