// profile_act.pde
// this module contains the routines selected by the profile selection from the main menu
// this includes the profile routines menu, receiving a new profile from a PC, editing a profile and displaying a profile.
//
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

/* 

*/
boolean start_prof = false;  //flag set when start of profile character is found in the serial data stream
int char_cnt = 0;            //counter for number of bytes or characters in the serial data
int k = 0;
//int prof_no = 0;
int prof_ind = 0;
int val = 0;
int digit = 0;
boolean done_8 = false;
boolean pick_8 = false;

// ------------------------------------------------------------------------

//

void receive_profile ()
{
byte in_byte[sizeof( myprofile )];  //input array, set to size of one profile of data
byte *ptr;
char aChar;
//char tempchar;

//Serial.flush(); // clear the serial buffer before reading new data 

serial_send_start_dl();  //send message to PC to start download of profiles
ptr = &in_byte[0];      //set to point to array
byte counter;
val = 0;
digit = 0;
boolean done_3 = false;

while (done_3 == false) {
    if (Serial.available() > 0) {
        aChar = Serial.read();
        if (aChar == '@') {  //start of profile character, init to read in a new profile
            start_prof = true;
            char_cnt = 0;
            k=0;
            }
        else if (start_prof == true) {  //read in chars in the beginning of the profile
            if (char_cnt < (NAME_LENGTH+DATE_LENGTH)){
                char_cnt++;
                in_byte[k++] = aChar;
                }
               //char cnt is past chars, so we are only reading numbers now.  All numbers are comma seperated, so use comma as flag to read in the number
            else   {
               if (aChar == ',') {
                    //the following two lines convert integer val to two bytes to store in in_byte
                    in_byte[k++] = (val & 0xFF);         //read in the lsb
                    in_byte[k++] = ((val >> 8) & 0xFF);  //read in the msb
                    val = 0;
                    digit = 0;
                    char_cnt++;
                    }
                else if (aChar == '*')  {  // check for end of profile char
                    prof_ind = in_byte[(NAME_LENGTH+DATE_LENGTH)];
                    if (prof_ind < MAX_PROFILE) {
                       write_profile(prof_ind, ptr);}
                    start_prof = false;
                    val = 0;
                    digit = 0;
                    lcd.print ("+");
                    }
                else if (aChar == '^')  {  // check for end of file/transmission char
                    prof_ind = in_byte[(NAME_LENGTH+DATE_LENGTH)];
                    if (prof_ind < MAX_PROFILE) {
                       write_profile(prof_ind, ptr);}
                    done_3 = true;
                    lcd.print (" e");
                    }
                else {
                    if(aChar >= '0' && aChar <= '9') {
                        //this code converts ascii to integer
                        val *= 10;
                        digit = aChar - '0';
                        val += digit;
                        char_cnt++;
                        }
                    }
                }
//            if (char_cnt == (NAME_LENGTH+DATE_LENGTH+10)){
//               tempchar =  in_byte[(NAME_LENGTH+DATE_LENGTH)];          
//               lcd.print( tempchar);
//              }
                
                
            }  
        }  //end if (Serial.available)   
    }               
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
void edit_profile()
{
int ptr;
int param;
int ii = 0;
boolean done_7 = false;
boolean selected_7 = false;
boolean done_9 = false;
boolean selected_9 = false;
int *pt;

done_8 = false;
pick_8 = false;

//first choose profile to edit, and load the profile into the structure myprofile
  while (selected_9 == false) {
    if (select_profile() == true) {//this routine is in pick_profile.pde.  It is true if esc was pushed, false if select was pushed
      done_9 = true;    //done if esc was pushed
      }
    selected_9 = true;  //when we return from select_profile(), something was selected
    }  //end while selected is false

param=0;

//now choose which parameter to edit, ie ror, time, targ_temp, etc
while (done_7 == false) {
  dsp_function = &display_prof_param_select; //function pointer, point to function to display screen for this selection
  pt = &param;      //set this pointer to param variable
  done_7 = ( select_something (9, pt) ) ;//select_something is a function in util.pde
//  done_7 = ( select_something (4, pt) ) ;//select_something is a function in util.pde
  if (done_7 == false) {
   if (param == 9)  {  //param = 9 = max temp, only param that is not a row of values
     done_8 = true; }  //skip the while loop if editing max temp 
   else {
     done_8 = false; }
  //now choose which param number (within a row, so between 0 and 14) to edit 
  while (done_8 == false) {
    dsp_function = &display_select_param_no; //function pointer, point to function to display screen for this selection
    pt = &ii;      //set pointer to the input array
    done_8 = ( select_something (13, pt) ) ;
    if (done_8 == false) {
  //now set the edit point to the address of the selected parameter to change    
      if (param == 0) {
         edit_ptr = &myprofile.ror[ii]; 
         inc = 5;
         }
      else if (param == 1) {
         edit_ptr = &myprofile.targ_temp[ii]; 
         inc = 5;
         }
      else if (param == 2) {
         edit_ptr = &myprofile.time[ii]; 
         inc = 5;
         }  
      else if (param == 3) {
         inc = 5;
         edit_ptr = &myprofile.offset[ii]; 
         }  
      else if (param == 4) {
         edit_ptr = &myprofile.speed[ii]; 
         inc = 5;   
         }  
      else if (param == 5) {
         edit_ptr = &myprofile.delta_temp[ii]; 
         inc = 5;   
         }  
      edit_param();  //call this function, it is in util.pde
     }  //end if done_8 false
    }//if while done_8
  if (param == 9) {
     edit_ptr = &myprofile.maxtemp; 
     inc = 5;   
     edit_param();  //call this function, it is in util.pde
     }  
 
  }//end if done_7
  }//end while done_7
  write_profile ( prof_cntr );  

}

*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void show_profile()
{
int j;
int k=0;
boolean done_2 = false;
boolean selected_2 = false;
while (done_2 == false) {
  while (selected_2 == false) {
    if (select_profile() == true) {//routine in pick_profile.pde  is true if esc was pushed, false if select was pushed
      done_2 = true;    //done if esc was pushed
      }
    selected_2 = true;  //when we return from select_profile(), something was selected
    }  //end while selected is false

  j=0;  
  selected_2=false;  //init selected to false again so while loop will run again
  while ((done_2 == false) && (j<6)) {  //does until all sets of param values are displayed
      display_profile_row(j++);  //displays one set of param values, either ror or temp or time etc.
      buttonValue = wait_button();  //wait for keypress to go to next profile
      if (buttonValue == ESCAPE) {
         j=7; //if esc, set j to a value to exit this while loop
         //done_2 = true;
         //selected = true;
      }
    }
  }// end of while done is false
}  



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
boolean pick_1 = false;

int act01;

void profile_act()
{
act01 = 0;
boolean done_1 = false;
boolean pick_1 = false;
int *ptr;
ptr = &act01;      //set pointer to the input array

while (done_1==false) {
  dsp_function = &display_select_prof_act; 
  done_1 = ( select_something (2, ptr) ) ;
  if (done_1==false){
    if (act01 == 0) {
      show_profile();	
      }
//    else if (act01 == 1) {
//      edit_profile();
//      }
//    else if (act01 == 2) { 
//      edit_profile();
//      }
    }  
  }//end while done
} // end routine
*/
