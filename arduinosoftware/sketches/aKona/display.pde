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


// ------------------------------------------------------------------------
// this routine displays the startup screen when the program begins
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
//    K o n a   V v v v v v         
    
void display_startup()
{
lcd.clear();
lcd.home();
lcd.print("Kona V");
lcd.print (VERSION);
} // end routine

// ------------------------------------------------------------------------
// this routine displays the profile name on the LCD
//	2x16 display format
//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
//    P r o f i l e   N a m e :         
//    n n n n n n n n n n n n n n n n
	
void display_profile(int cnt)
{
int i;
lcd.clear();
lcd.home();
lcd.print("Sel Profile ");
lcd.print (cnt);
lcd.setCursor(0,1);
for (i = 0; i < 16; i++) {   //send name of this profile to display
	lcd.print(Profile_Name_buffer[i]);
	}
}
// ------------------------------------------------------------------------
// this routine display ask to verify to end roast now
/*  
	2x16 display format
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
    E n d   R o a s t ?   P u s h        
    S E L E C T   t o   v e r i f y     
*/
void display_ask_end()
{
	lcd.clear();
	lcd.home();
	lcd.print("End roast? Push");
	lcd.setCursor(0,1);
	lcd.print("SELECT to verify");
}

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
  lcd.print("Cooling");
	
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
	lcd.print("Roast complete");
	lcd.setCursor(0,1);
	lcd.print("  turn off");
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
	lcd.print("Select Mode = ");
	lcd.print(roast_mode);
	lcd.setCursor(0,1);
		
	
	if (roast_mode == 3) {   //if in manual ror roast method
	lcd.print("Manual ROR");  
	}
	else if (roast_mode == 2) {   //
		lcd.print("Change I & D");  
	}
	else if (roast_mode == 1) {   //
		lcd.print("Change Pb & FS");  
	}
	else {   
		lcd.print("Change TT or ROR");  
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
	lcd.print("RoastMode=");
	lcd.print(roast_mode);
	lcd.setCursor(0,1);
	lcd.print("Push to cont");
        wait_button();
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
  tmp = round(I);
  lcd.print(tmp);
   lcd.setCursor(14,1);
  tmp = round(D);
  lcd.print(tmp);
}
else if (roast_mode == 1) {   //
	lcd.setCursor(12,0);
	lcd.print(" Pb");  
  lcd.setCursor(13,1);
  tmp = round(Pb);
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
		lcd.print( " FS:");    //12-15
		//dsp_int = delta_temp;          //round off setpoint to type int to display it
		lcd.print(FanSpeed);    //16-19
        break;
	case (1):  //can change Pb and , so display associated params
		//display Pb constant term
		lcd.print( " Pb:");      // 
		dsp_int = Pb;          //round off setpoint to type int to display it
		lcd.print(dsp_int);    //
 		lcd.print( " FS:");      // 
		dsp_int = Pb;          //round off setpoint to type int to display it
		lcd.print(FanSpeed);    //
        break;
	case (2):  //can change I and D, so display associated params
		//display I constant term
		lcd.print( " I:"); //
		lcd.print(I);    //	
		//display I constant term
		lcd.print(" D");       //
		lcd.print(D);    //
        break;
	case (3):  //can change ROR and FS, so display associated params
		//display ROR
		lcd.print( " ROR"); //
		lcd.print(ROR);    //	
		//display FS
		lcd.print(" FS");       //
		lcd.print(FanSpeed);    //
        break;
	}
}
} // end routine


