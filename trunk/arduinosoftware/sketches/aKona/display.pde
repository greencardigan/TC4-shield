// display.pde
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

/* display is a 20x4 Character LCD Module
The routines in this file/tab format and send the data to the LCD display

*/

//set up constants used to display static text.  This method (progmem) saves RAM.
#include <avr/pgmspace.h>


//                                   12345678911234567892
prog_char dsp_str_00[] PROGMEM = "Kona Ver ";   // "dsp_str 00" etc are strings used for lcd display.
prog_char dsp_str_01[] PROGMEM = "Cooling";
prog_char dsp_str_02[] PROGMEM = "Push any button ";
prog_char dsp_str_03[] PROGMEM = "to start roast";
prog_char dsp_str_04[] PROGMEM = "Select Action "; 
prog_char dsp_str_05[] PROGMEM = "Roast";
prog_char dsp_str_06[] PROGMEM = "Profile";
prog_char dsp_str_07[] PROGMEM = "Configure";
prog_char dsp_str_000[] PROGMEM = "Profile Receive";
prog_char dsp_str_001[] PROGMEM = "Profile Edit";
prog_char dsp_str_10[] PROGMEM = "Profile Read";
prog_char dsp_str_11[] PROGMEM = "Select Mode = ";
prog_char dsp_str_12[] PROGMEM = "Manual ROR";
prog_char dsp_str_13[] PROGMEM = "Change I & D";
prog_char dsp_str_14[] PROGMEM = "Change Pb & FS";
prog_char dsp_str_15[] PROGMEM = "Change TT or ROR";
prog_char dsp_str_16[] PROGMEM = "RoastMode = ";
prog_char dsp_str_17[] PROGMEM = "Push to cont";
prog_char dsp_str_100[] PROGMEM = "";    //not usable
prog_char dsp_str_101[] PROGMEM = "";    //not usable
prog_char dsp_str_20[] PROGMEM = "Edit EEprom";
prog_char dsp_str_21[] PROGMEM = "Read EEprom";
prog_char dsp_str_22[] PROGMEM = "Select Param ";
prog_char dsp_str_23[] PROGMEM = "Pb ";
prog_char dsp_str_24[] PROGMEM = "I ";
prog_char dsp_str_25[] PROGMEM = "D ";
prog_char dsp_str_26[] PROGMEM = "PID Factor ";
prog_char dsp_str_27[] PROGMEM = "Start Temp ";
prog_char dsp_str_200[] PROGMEM = "";    //not usable
prog_char dsp_str_201[] PROGMEM = "";    //not usable
prog_char dsp_str_30[] PROGMEM = "Segment 2 ";
prog_char dsp_str_31[] PROGMEM = "Seg 0 Bias ";
prog_char dsp_str_32[] PROGMEM = "Seg 1 Bias ";
prog_char dsp_str_33[] PROGMEM = "Seg 2 Bias ";
prog_char dsp_str_34[] PROGMEM = "Seg 0 Min ";
prog_char dsp_str_35[] PROGMEM = "Seg 1 Min ";
prog_char dsp_str_36[] PROGMEM = "Seg 2 Min ";
prog_char dsp_str_37[] PROGMEM = ",";
prog_char dsp_str_300[] PROGMEM = "";    //not usable
prog_char dsp_str_301[] PROGMEM = "";    //not usable
prog_char dsp_str_40[] PROGMEM = "Profile Receive";
prog_char dsp_str_41[] PROGMEM = "Profile Edit";
prog_char dsp_str_42[] PROGMEM = "Param value is ";
prog_char dsp_str_43[] PROGMEM = "Init EEprom";
prog_char dsp_str_44[] PROGMEM = "";
prog_char dsp_str_45[] PROGMEM = "";
prog_char dsp_str_46[] PROGMEM = "Max Temp ";
prog_char dsp_str_47[] PROGMEM = "Segment 1 ";
prog_char dsp_str_400[] PROGMEM = "";    //not usable
prog_char dsp_str_401[] PROGMEM = "";    //not usable
prog_char dsp_str_50[] PROGMEM = "Roast complete";
prog_char dsp_str_51[] PROGMEM = "  turn off";
prog_char dsp_str_52[] PROGMEM = "Start Heat";
prog_char dsp_str_53[] PROGMEM = " ror";
prog_char dsp_str_54[] PROGMEM = " target temp";
prog_char dsp_str_55[] PROGMEM = " time";
prog_char dsp_str_56[] PROGMEM = " offset";
prog_char dsp_str_57[] PROGMEM = " fan speed";
prog_char dsp_str_500[] PROGMEM = "";    //not usable
prog_char dsp_str_501[] PROGMEM = "";    //not usable
prog_char dsp_str_60[] PROGMEM = "Pick param number";
prog_char dsp_str_61[] PROGMEM = "Delta Temp";
prog_char dsp_str_62[] PROGMEM = "TBD Row 7";
prog_char dsp_str_63[] PROGMEM = "TBD Row 8";
prog_char dsp_str_64[] PROGMEM = "TBD Row 9";

// Then set up a table to refer to your strings.

PROGMEM const char *dsp_str_table[] = 	   // change "dsp_str_table" name to suit
{   
  dsp_str_00,  //00
  dsp_str_01,  //01
  dsp_str_02,  //02
  dsp_str_03,  //03
  dsp_str_04,  //04
  dsp_str_05,   //05
  dsp_str_06,   //06
  dsp_str_07,   //07
  dsp_str_000,   //08
  dsp_str_001,   //09
  dsp_str_10,   //10
  dsp_str_11,   //11
  dsp_str_12,   //12
  dsp_str_13,   //13
  dsp_str_14,   //14
  dsp_str_15,   //15
  dsp_str_16, 
  dsp_str_17, 
  dsp_str_100, 
  dsp_str_101,   
  dsp_str_20,   //20
  dsp_str_21, 
  dsp_str_22,
  dsp_str_23,
  dsp_str_24,
  dsp_str_25,
  dsp_str_26,
  dsp_str_27,
  dsp_str_200,
  dsp_str_201,
  dsp_str_30,   //30
  dsp_str_31, 
  dsp_str_32,
  dsp_str_33,
  dsp_str_34,
  dsp_str_35,
  dsp_str_36,
  dsp_str_37,
  dsp_str_300, 
  dsp_str_301,
  dsp_str_40, //40
  dsp_str_41,
  dsp_str_42,
  dsp_str_43,
  dsp_str_44,
  dsp_str_45,
  dsp_str_46,
  dsp_str_47,
  dsp_str_400,
  dsp_str_401,
  dsp_str_50,  //50
  dsp_str_51,  
  dsp_str_52,
  dsp_str_53,  
  dsp_str_54,  
  dsp_str_55,  
  dsp_str_56,  
  dsp_str_57,    
  dsp_str_500,
  dsp_str_501,
  dsp_str_60,   //60
  dsp_str_61,
  dsp_str_62,
  dsp_str_63,
  dsp_str_64
  };


prog_char dsp_num_00[] PROGMEM = "0";


// ------------------------------------------------------------------------
// this routine displays the startup screen when the program begins
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
//    K o n a   V v v v v v         
    
void display_startup()
{
lcd.clear();
lcd.home();
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[00]))); // Necessary casts and dereferencing
lcd.print( char_buf);
//lcd.print("Kona Ver ");  //string_00

lcd.print (VERSION); 
} // end routine

// ------------------------------------------------------------------------
// this routine displays the startup screen when the program begins
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
//    K o n a   V v v v v v         
    
void display_start_roast()
{
lcd.clear();
lcd.home();
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[02]))); // Necessary casts and dereferencing
lcd.print( char_buf);
//lcd.print("Push any button ");  //string_02
lcd.setCursor(0,1); 
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[03]))); // Necessary casts and dereferencing
lcd.print( char_buf);
//lcd.print("to start roast");   //string_03
} // end routine



// ------------------------------------------------------------------------
// this routine displays the startup screen when the program begins
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9
//            
   
void display_select_action(int act)
{
lcd.clear();
lcd.home();
	//lcd.print("Select Action ");  //string_04
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[04]))); // Necessary casts and dereferencing
lcd.print( char_buf);

lcd.setCursor(0,1);    
if (act == 0) {
  strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[05]))); // Necessary casts and dereferencing
  lcd.print( char_buf);
  //lcd.print ("Roast");  //string_05
  }
else if (act == 1) {
  strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[06]))); // Necessary casts and dereferencing
  lcd.print( char_buf);
  //lcd.print ("Profile");  //string_06
  }
else if (act == 2) {
  strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[07]))); // Necessary casts and dereferencing
  lcd.print( char_buf);
  //  lcd.print ("Configure");  //string_07
  }  

} // end routine


// ------------------------------------------------------------------------
// this routine displays the screen to select the action when profile is selected
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9
//            
   
void display_select_prof_act(int act)
{
   	lcd.clear();
	lcd.home();
	//lcd.print("Select Action ");  //string_04
	strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[04]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
        lcd.setCursor(0,1);    
	if (act == 0) {
	   //lcd.print ("Profile Read");   //string_10
           strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[10]))); // Necessary casts and dereferencing
           lcd.print( char_buf);
	   }
	else if (act == 1) {
	   //lcd.print ("Profile Edit");   //string_41
           strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[41]))); // Necessary casts and dereferencing
           lcd.print( char_buf);
	   }
	else if (act == 2) {
	   //lcd.print ("Profile Edit");   //string_41
           strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[41]))); // Necessary casts and dereferencing
           lcd.print( char_buf);
	   }  

} // end routine



// ------------------------------------------------------------------------
// this routine displays the profile name on the LCD
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
//    P r o f i l e   N a m e :         
//    n n n n n n n n n n n n n n n n
	
void display_profile(int k)
{
int i;

lcd.clear();
lcd.home();
//lcd.print (k);
//lcd.print (" ");
lcd.print (myprofile.index);
lcd.print (" ");
for (i = 0; i < 20; i++) {   //send name of this profile to display
  lcd.print(myprofile.name[i]);
  }

lcd.setCursor(0,1);
for (i = 0; i < 16; i++) {   //send date of this profile to display
  lcd.print(myprofile.date[i]);
  }

lcd.setCursor(0,2);
lcd.print(myprofile.profile_method);
lcd.print(myprofile.maxtemp);

} // end routine

// ------------------------------------------------------------------------
// this routine displays one row (ror or temp or time etc) for a profile
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
//    K o n a   V v v v v v         

// k=0 display name and display time/date
//k=1 display ror
//k=2 display temp
//k=3 display time
//k=4 display offset
//k=5 display fan speed

void display_profile_row(int k)
{
int i;

lcd.clear();
lcd.home();

if (k==0) {
    lcd.print (myprofile.index);
    lcd.setCursor(0,1);
    for (i = 0; i < 16; i++) {   //send name of this profile to display
	lcd.print(myprofile.name[i]);
	}
    lcd.setCursor(0,2);
    for (i = 0; i < 16; i++) {   //send name of this profile to display
	lcd.print(myprofile.date[i]);
	}
    lcd.setCursor(0,3);
    //lcd.print(sizeof( myprofile ));
    lcd.print(myprofile.maxtemp);
    }
else if (k==1) {
    lcd.print (myprofile.index);
    strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[53]))); // Necessary casts and dereferencing
    lcd.print( char_buf);
    lcd.setCursor(0,1);
    i = 0;
    while (i < 14) {   //send ror of this profile to display
	lcd.print(myprofile.ror[i++]);
        lcd.print (",");

        if (i==5) {    lcd.setCursor(0,2);}
        if (i==10) {    lcd.setCursor(0,3);}
        }
    }

else if (k==2) {
    lcd.print (myprofile.index);
    strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[54]))); // Necessary casts and dereferencing
    lcd.print( char_buf);
    lcd.setCursor(0,1);
    i = 0;
    while (i < 14) {   //send target temp of this profile to display
	lcd.print(myprofile.targ_temp[i++]);
        lcd.print (",");

        if (i==5) {    lcd.setCursor(0,2);}
        if (i==10) {    lcd.setCursor(0,3);}
        }
    }

else if (k==3) {
    lcd.print (myprofile.index);
    strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[55]))); // Necessary casts and dereferencing
    lcd.print( char_buf);
    lcd.setCursor(0,1);
    i = 0;
    while (i < 14) {   //send time of this profile to display
	lcd.print(myprofile.time[i++]);
        lcd.print (",");

        if (i==5) {    lcd.setCursor(0,2);}
        if (i==10) {    lcd.setCursor(0,3);}
        }
    }

else if (k==4) {
    lcd.print (myprofile.index);
    strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[56]))); // Necessary casts and dereferencing
    lcd.print( char_buf);
    lcd.setCursor(0,1);
    i = 0;
    while (i < 14) {   //send offset of this profile to display
	lcd.print(myprofile.offset[i++]);
        lcd.print (",");

        if (i==5) {    lcd.setCursor(0,2);}
        if (i==10) {    lcd.setCursor(0,3);}
        }
    }

else if (k==5) {
    lcd.print (myprofile.index);
    strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[57]))); // Necessary casts and dereferencing
    lcd.print( char_buf);
    lcd.setCursor(0,1);
    i = 0;
    while (i < 14) {   //send fan speed of this profile to display
	lcd.print(myprofile.speed[i++]);
        lcd.print (",");

        if (i==5) {    lcd.setCursor(0,2);}
        if (i==10) {    lcd.setCursor(0,3);}
        }
    }

} // end routine
// ------------------------------------------------------------------------
// this routine displays screen during end of roast/cooling cycle
/*  
	2x16 display format
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    m m : s s   C T : t t t      
    M T : t t t     C o o l i n g 
    Cooling           
*/
void display_ending()
{
	lcd.clear();
	lcd.home();
	// print the TOD in min:sec format
  int tmp = round( tod );
  if( tmp > 3599 ) tmp = 3599;
  lcd.print(tmp/60);     //0-1
  lcd.print(":");          // 2
  lcd.print(tmp%60);     //3-4

  // format and display ct
  tmp = round( ct );
  if( tmp > 999 ) tmp = 999;
  lcd.setCursor(5,0);    
  lcd.print (" CT:" );  //5-9
  lcd.print (tmp);       //9-11
	
	lcd.setCursor(0,1);

  //format and display mt
  lcd.setCursor(0,1);    
  tmp = round(mt);
  if( tmp > 999 ) tmp = 999;
  else if( tmp < -999 ) tmp = -999;  
  lcd.print ("MT:");    //00-01
  lcd.print(tmp);     //2-4

  lcd.setCursor(8,1);
  strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[01]))); // Necessary casts and dereferencing
  lcd.print( char_buf);  
//lcd.print("Cooling");
	
}

// ------------------------------------------------------------------------
// this routine displays the end of roast screen.
/*  
	2x16 display format
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    R o a s t   c o m p l e t e        
    T u r n   o f f     
*/

void display_end()
{
	lcd.clear();
	lcd.home();
//	lcd.print("Roast complete");
        strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[50]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
	lcd.setCursor(0,1);
        strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[51]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
//	lcd.print("  turn off");
}

// ------------------------------------------------------------------------
// this routine displays the menu to pick the roast mode.
/*  
	2x16 display format
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    S e l e c t   M o d e   =   m   
    M a n u a l   R O R
	C h a n g e   I   &   D
	C h a n g e   P b   &   F S
	C h a n g e   T T   o r   R O R
*/
void display_roast_menu()
{
	lcd.clear();
	lcd.home();
        strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[11]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
	//lcd.print("Select Mode = ");      //string_11
	lcd.print(roast_mode);
	lcd.setCursor(0,1);
		
	
	if (roast_mode == 3) {   //if in manual ror roast method
	  strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[12]))); // Necessary casts and dereferencing
          lcd.print( char_buf);
          //lcd.print("Manual ROR");            //string_12
	  }
	else if (roast_mode == 2) {   //
	  //lcd.print("Change I & D");   //string_13
          strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[13]))); // Necessary casts and dereferencing
          lcd.print( char_buf);
	  }
	else if (roast_mode == 1) {   //
//		lcd.print("Change Pb & FS");   //string_14
          strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[14]))); // Necessary casts and dereferencing
          lcd.print( char_buf);
	  }
	else {   
//		lcd.print("Change TT or ROR");   //string_15
          strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[15]))); // Necessary casts and dereferencing
          lcd.print( char_buf);
	  }
}

// ------------------------------------------------------------------------
// this routine displays the roast mode selected
/*  
	2x16 display format
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    R o a s t   M o d e = m     
    P u s h   t o   c o n t
*/
void display_roast_mode()
{
	lcd.clear();
	lcd.home();
	//lcd.print("RoastMode = ");    //string_16
        strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[16]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
	lcd.print(roast_mode);
	lcd.setCursor(0,1);
        strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[02]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
//	lcd.print("Push any button ");    //string_02
        wait_button();
}

// ------------------------------------------------------------------------
void display_PID_param_show(int param)
{

lcd.clear();
lcd.home();
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[22]))); // Necessary casts and dereferencing
lcd.print( char_buf);
//lcd.print("Select Param ");
lcd.setCursor(0,1);    
if (param == 0) {
//   lcd.print ("Pb");
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[23]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
   lcd.print( myPID.Pb);
   edit_flt_ptr = &myPID.Pb; 
   inc_flt = 1;
   }
else if (param == 1) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[24]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("I");
   lcd.print( myPID.I);
   edit_flt_ptr = &myPID.I; 
   inc_flt = 0.5;
	}
else if (param == 2) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[25]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("D");
   edit_flt_ptr = &myPID.D; 
   inc_flt = 0.5;
   lcd.print( myPID.D);
   }  
else if (param == 3) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[26]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("PID Factor");
   lcd.print( myPID.PID_factor);
   inc_flt = 0.1;
   edit_flt_ptr = &myPID.PID_factor; 
   }  
else if (param == 4) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[27]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("Start Temp");
    lcd.print( myPID.starttemp);
   edit_ptr = &myPID.starttemp; 
   inc = 5;   
		}  
else if (param == 5) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[46]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("Max Temp");
    lcd.print( myPID.maxtemp);
   edit_ptr = &myPID.maxtemp; 
   inc = 5;   
   }  
else if (param == 6) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[47]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("Segment 1");
    lcd.print( myPID.segment_1);
   edit_ptr = &myPID.segment_1; 
   inc = 1;   
   }  
else if (param == 7) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[30]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("Segment 2");
    lcd.print( myPID.segment_2);
   edit_ptr = &myPID.segment_2; 
   inc = 1;   
   }  
else if (param == 8) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[31]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//  lcd.print ("Seg 0 Bias");
  lcd.print( myPID.seg0_bias);
   edit_ptr = &myPID.seg0_bias; 
   inc = 5;   
   }  
else if (param == 9) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[32]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//  lcd.print ("Seg 1 Bias");
    lcd.print( myPID.seg1_bias);
  edit_ptr = &myPID.seg1_bias;    
   inc = 5;   
   }  
else if (param == 10) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[33]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("Seg 2 Bias");
    lcd.print( myPID.seg2_bias);
   edit_ptr = &myPID.seg2_bias;
   inc = 5;   
   }  
else if (param == 11) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[34]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
 //  lcd.print ("Seg 0 Min");
     lcd.print( myPID.seg0_min);
   edit_ptr = &myPID.seg0_min; 
   inc = 5;   
   }  
else if (param == 12) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[35]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//lcd.print ("Seg 1 Min");
    lcd.print( myPID.seg1_min);
   edit_ptr = &myPID.seg1_min; 
   inc = 5;   
   }  
else if (param == 13) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[36]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("Seg 2 Min");
    lcd.print( myPID.seg2_min);
   edit_ptr = &myPID.seg2_min; 
   inc = 5;   
   }  
else if (param == 14) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[52]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("Start Heat");
    lcd.print( myPID.startheat);
   edit_ptr = &myPID.startheat; 
   inc = 5;   
   }  
}

// ------------------------------------------------------------------------
// this routine displays the screen to select the profile param to edit
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9
//            
/*   
void display_prof_param_select(int param)
{

lcd.clear();
lcd.home();
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[22]))); // Necessary casts and dereferencing
lcd.print( char_buf);
//lcd.print("Select Param ");
lcd.setCursor(0,1);    
if (param == 0) {
//   lcd.print ("ror");
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[53]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
   }
else if (param == 1) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[54]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("temp");
   }
else if (param == 2) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[55]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("time");
   }  
else if (param == 3) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[56]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("offset");
   }  
else if (param == 4) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[57]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("fan speed");
   }  
else if (param == 5) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[61]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("delta temp");

   }  
   else if (param == 6) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[62]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("tbd row 7");

   }  
else if (param == 7) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[63]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("tbd row 8");
 
   }  
else if (param == 8) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[64]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("tbd row 9");

   }  

else if (param == 9) {
   strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[46]))); // Necessary casts and dereferencing
   lcd.print( char_buf);
//   lcd.print ("max temp");
   edit_ptr = &myprofile.maxtemp; 
   inc = 5;   
   }  

} // end routine
*/

// ------------------------------------------------------------------------
// this routine displays the screen to select the parameter number in a row in the profile to edit
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9
//            
/*   
void display_select_param_no(int ii)
{
   	lcd.clear();
	lcd.home();
	//lcd.print("Pick param number");
	strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[60]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
        lcd.setCursor(0,1);    
        lcd.print (ii);

} // end routine


*/
// ------------------------------------------------------------------------
// this routine displays the screen to select the action when profile is selected
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9
//            
   
void display_select_con_act(int act)
{
   	lcd.clear();
	lcd.home();
	//lcd.print("Select Action ");
	strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[04]))); // Necessary casts and dereferencing
        lcd.print( char_buf);
        lcd.setCursor(0,1);    
	if (act == 0) {
	   //lcd.print ("Init EEprom");
           strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[43]))); // Necessary casts and dereferencing
           lcd.print( char_buf);
	   }
	else if (act == 1) {
           strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[20]))); // Necessary casts and dereferencing
           lcd.print( char_buf);
//	   lcd.print ("Edit EEprom");
	   }
	else if (act == 2) {
           strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[21]))); // Necessary casts and dereferencing
           lcd.print( char_buf);
//	   lcd.print ("Read EEprom");
	   }  

} // end routine


// ------------------------------------------------------------------------
// this routine displays the 
void display_edit_flt_param() {
lcd.clear();
lcd.home();
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[42]))); // Necessary casts and dereferencing
lcd.print( char_buf);
//lcd.print("Param value is ");  string18
lcd.setCursor(0,1);    
lcd.print (*edit_flt_ptr);  
 
  
}
  
 
// ------------------------------------------------------------------------
// this routine displays the 
void display_edit_param() {
lcd.clear();
lcd.home();
strcpy_P(char_buf, (char*)pgm_read_word(&(dsp_str_table[42]))); // Necessary casts and dereferencing
lcd.print( char_buf);
//lcd.print("Param value is ");  string18
lcd.setCursor(0,1);    
lcd.print (*edit_ptr);  
 
  
}


// ------------------------------------------------------------------------
// this routine displays the information on the LCD during the roast


/*  display format
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9
    m m : s s   C T : t t t   R O R   C N T     
    M T t t t   S P : s s s   r r r   s s
    P : p p p   I : i i i   D : d d d                        
    H : h h h   R O R : r o r
	
	2x16 display format - normal
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    m m : s s   C T : t t t   R O R    
    M T t t t   S P : s s s   r r r   
	
*/
 
void display_roast()
{
int dsp_int;
float dsp_temp;
// Print LCD Line 1 with PID info


//Row 1
lcd.clear();
lcd.home();

// print the TOD in min:sec format
int tmp = round( tod );
if( tmp > 3599 ) tmp = 3599;
lcd.print(tmp/60);     //0-1
lcd.print(":");          // 2
lcd.print(tmp%60);     //3-4

// format and display ct
tmp = round( ct );
if( tmp > 999 ) tmp = 999;
lcd.setCursor(5,0);    
lcd.print (" CT:" );  //5-9
lcd.print (tmp);       //9-11

if (COLS > 16) {        //display this info only for displays with >16 columns, intended for 4x20 display
  lcd.setCursor(16,0);
  lcd.print (" CNT" );  //
}


//Row 2
lcd.setCursor(0,1);

//format and display mt
tmp = round(mt);
if( tmp > 999 ) tmp = 999;
else if( tmp < -999 ) tmp = -999;  
lcd.print ("MT");    //00-01
lcd.print(tmp);     //2-4

//lcd.setCursor(6,1);

//format and display the setpoint
lcd.setCursor(5,1);
lcd.print(" SP:");          //5-8
dsp_temp = setpoint + 0.5;  //set up setpoint to round off
dsp_int = dsp_temp;              //round off setpoint to type int to display it
lcd.print(dsp_int);  //9-11


//Format mt RoR
if (roast_mode == 3) {   //if in manual ror roast method, then display target ROR
	lcd.setCursor(12,0);
	lcd.print(" ROR");  
	lcd.setCursor(13,1);
        dsp_int = ROR;       
	lcd.print(dsp_int);  
	}
else if (roast_mode == 2) {   //
	lcd.setCursor(12,0);
	lcd.print(" I D");  
  lcd.setCursor(12,1);
  tmp = round(myPID.I);
  lcd.print(tmp);
   lcd.setCursor(14,1);
  tmp = round(myPID.D);
  lcd.print(tmp);
}
else if (roast_mode == 1) {   //
	lcd.setCursor(12,0);
	lcd.print(" Pb");  
  lcd.setCursor(13,1);
  tmp = round(myPID.Pb);
  lcd.print(tmp);
}
else if (roast_method == AUTO_TEMP) {   
	lcd.setCursor(12,0);
	lcd.print(" TT");  
  lcd.setCursor(13,1);
  tmp = round(target_temp);
  lcd.print(tmp);

}

else if (roast_method == AUTO_ROR) { 
	lcd.setCursor(12,0);
	lcd.print(" ROR");  
        lcd.setCursor(13,1);
        dsp_int = ROR;       
	lcd.print(dsp_int);  
	}

if (COLS > 16) {             //display this info only for displays with >16 columns, intended for 4x20 display
  lcd.setCursor(17,1);
  lcd.print(step_timer);     //step_timer is int
}


if (ROWS >= 3) {
//Row 3
lcd.setCursor(0,2);
lcd.print("S:");        //1-2
lcd.print(step);       // 3-4 step is int
lcd.setCursor(4,2);

//display Proportion term
lcd.print(" P");       // 5-6
dsp_temp = Proportion + 0.5;  //set up setpoint to round off
dsp_int = dsp_temp;              //round off setpoint to type int to display it
if( dsp_int > 99 ) dsp_int = 99;
else if( dsp_int < -99 ) dsp_int = -99; 
lcd.print(dsp_int);    //7-8

//display Integral term
lcd.print(" In");       //9-11
dsp_temp = Integral + 0.5;  //set up setpoint to round off
dsp_int = dsp_temp;              //round off setpoint to type int to display it
if( dsp_int > 99 ) dsp_int = 99;
else if( dsp_int < -99 ) dsp_int = -99; 
lcd.print(dsp_int);    //12-13

//display derivative term  
lcd.print(" De");       //14-16
dsp_temp = Derivative + 0.5;  //set up setpoint to round off
dsp_int = dsp_temp;              //round off setpoint to type int to display it
if( dsp_int > 99 ) dsp_int = 99;
else if( dsp_int < -99 ) dsp_int = -99; 
lcd.print(dsp_int);    //17-18 
}

if (ROWS >= 4) {
//Row 4
lcd.setCursor(0,3);

lcd.print("H:");         //1-2
if (heat >= 100) {tmp = 99;}
else {tmp = heat;}
lcd.print(tmp);         //3-4

switch (roast_mode){
	case (0):  //can change temp and time on the fly, so display associated params
		lcd.print( " ROR:");      //5-8
		dsp_int = ROR;          //round off setpoint to type int to display it
		lcd.print(dsp_int);    //9-11
		lcd.print( " TT:");    //12-15
            dsp_int = target_temp;              //change to type int to display it
		lcd.print(dsp_int);    //16-19
        break;
	case (1):  //can change Pb and , so display associated params
		//display Pb constant term
		lcd.print( " Pb:");      // 
		dsp_int = myPID.Pb;          //round off setpoint to type int to display it
		lcd.print(dsp_int);    //
 		lcd.print( " TT:");      //
            dsp_int = target_temp;              //change to type int to display it
		lcd.print(dsp_int);    //16-19
        break;
	case (2):  //can change I and D, so display associated params
		//display I constant term
		lcd.print( " I:"); //
		lcd.print(myPID.I);    //	
		//display I constant term
		lcd.print(" D");       //
		lcd.print(myPID.D);    //
        break;
	case (3):  //can change ROR and FS, so display associated params
		//display ROR
		lcd.print( " ROR"); //
		lcd.print(ROR);    //	
		//display FS
		lcd.print(" TT");       //
            dsp_int = target_temp;              //change to type int to display it
		lcd.print(dsp_int);    //16-19
        break;
	}
}
} // end routine


