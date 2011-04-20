//util.pde
/*
utilities

*/

boolean select_something_nowait (int upper_limit, int *value)
{

//act_1 = 0;
boolean done_ss = false;
boolean selected_ss = false;

//while (selected_ss == false) {
    buttonValue = get_button();   
    if (buttonValue == ESCAPE) {
      selected_ss = true;
      }
    if (buttonValue == SELECT) {
      selected_ss = true;
      done_ss = true;
      }
    else if (buttonValue == UP_PLUS) {
      *value = *value + 1;
      }
    else if (buttonValue == DOWN_MINUS) {
      *value = *value - 1;
      }     
    if (*value > upper_limit) {*value = 0;}
    if (*value < 0) {*value = upper_limit;}
    
    if (buttonValue != NOBUTTON) {  //if a button was pushed, update the display
       dsp_function (*value); 
       }

//    } //end while pick

//  }//end while done
 return (done_ss);
 
} // end routine

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
boolean select_something (int upper_limit, int *value)
{

//act_1 = 0;
boolean done_ss = false;
boolean selected_ss = false;

while (selected_ss == false) {
    dsp_function (*value);
    buttonValue = wait_button();   
    if (buttonValue == ESCAPE) {
      done_ss = true;
      selected_ss = true;
      }
    if (buttonValue == SELECT) {
      selected_ss = true;
      }
    else if (buttonValue == UP_PLUS) {
      *value = *value + 1;
      }
    else if (buttonValue == DOWN_MINUS) {
      *value = *value - 1;
      }     
    if (*value > upper_limit) {*value = 0;}
    if (*value < 0) {*value = upper_limit;}
    } //end while pick

//  }//end while done
 return (done_ss);
 
} // end routine

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void edit_flt_param() {

 
boolean done_5 = false;
//display_edit_flt_param();

while (done_5 == false) {
  display_edit_flt_param();
  buttonValue = wait_button();
  if (buttonValue == UP_PLUS) { // 
   //if ((last_button == true) and (second_last_button == true)){
    *edit_flt_ptr = *edit_flt_ptr + inc_flt;
    }
  else if (buttonValue == DOWN_MINUS) {  //
  //if ((last_button == true) and (second_last_button == true)) {
    *edit_flt_ptr =*edit_flt_ptr - inc_flt;
    }
  else if (buttonValue == SELECT) {  //
    done_5 = true;
    }
  else if (buttonValue == ESCAPE) {  //
    done_5 = true;
    }
//  display_edit_flt_param();
  }//end while 
  
  
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void edit_param() {

  
boolean done_6 = false;

while (done_6 == false) {
  display_edit_param();
  buttonValue = wait_button();
  if (buttonValue == UP_PLUS) { // 
    *edit_ptr = *edit_ptr+inc;
    }
  else if (buttonValue == DOWN_MINUS) {  //
    *edit_ptr =*edit_ptr-inc;
    }
  else if (buttonValue == SELECT) {  //
    done_6 = true;
    }
  else if (buttonValue == ESCAPE) {  //
    done_6 = true;
    }
  //display_edit_param();
  }//end while 
 
}


// ------------------------------------------------------------------------
// this routine reads a sting, and converts the values to an int

int convert_int ()
{
 char int_Char;
 boolean con_done;

con_done = false;
in_val = 0;
in_digit = 0;
   
while (con_done == false) {
   //int_Char = *point;
   int_Char = *byte_ptr;
   byte_ptr++;
   
   if(int_Char >= '0' && int_Char <= '9') {
   //this code converts ascii to integer
       in_val *= 10;
       in_digit = int_Char - '0';
       in_val += in_digit;
       }
   if ((int_Char == '^')||(int_Char == ',')) {  //look for end of transmission char, or for number seperator comma
   //the following two lines convert integer val to two bytes to store in in_byte
       con_done = true; 
       }
   }
return (in_val);
   
}

// ------------------------------------------------------------------------
// this routine reads a sting, and converts the values to a float

float convert_float ()
{
 char int_Char;
 float fl_digit = 0;
 float fl_temp = 0;
 float fraction = 0;
 boolean conv_done = false;
 
fl_digit = 0;
fl_temp = 0;
fraction = 0;
conv_done = false;
  
while (conv_done == false) {
   int_Char = *byte_ptr;
   byte_ptr++;

   if(int_Char >= '0' && int_Char <= '9') {
   //this code converts ascii to integer
      fl_temp *= 10;
      fl_digit = int_Char - '0';
      fl_temp += fl_digit;
      }
   else if (int_Char == '.') {  //look for decimal point
      int_Char = *byte_ptr;  //read in digit after the decimal point
      byte_ptr++;
      fraction = (int_Char  - '0') * 0.1;
      fl_temp = fl_temp + fraction;
      conv_done = true; 
      }
   else if ((int_Char == '^')||(int_Char == ',')) {  //look for end of transmission char, or for number seperator comma
   //the following two lines convert integer val to two bytes to store in in_byte
      conv_done = true; 
      }
      
   }
return (fl_temp);
   
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void update_eeprom(int param_no, float value)
{

int ptr;
int param;
int *pt;

pt = &param;      //set pointer to the input array

ptr = PROFILE_ADDR_PID;//init pointer to the start address of the PID info

ep.read( ptr, (uint8_t*)&myPID, sizeof( myPID ) );  

if (param_no == 1) {
   myPID.Pb = value;}
else if (param_no == 2) {
   myPID.I = value;}  
else if (param_no == 3) {
   myPID.D = value; }
else if (param_no == 4) {
   myPID.PID_factor = value;}
else if (param_no == 5) {
   myPID.starttemp = value ;}
else if (param_no == 6) {
   myPID.maxtemp = value ;}
else if (param_no == 7) {
   myPID.segment_0 = value;}
else if (param_no == 8) {
   myPID.segment_1 = value;}
else if (param_no == 9) {
   myPID.segment_2 = value;}
else if (param_no == 10) {
   myPID.seg0_bias = value ;}
else if (param_no == 11) {
   myPID.seg1_bias =  value;}
else if (param_no == 12) {
   myPID.seg2_bias = value ;}
else if (param_no == 13) {
   myPID.seg0_min = value ;}
else if (param_no == 14) {
   myPID.seg1_min = value ;}
else if (param_no == 15) {
   myPID.seg2_min = value ;}
else if (param_no == 16) {
   myPID.startheat = value ;}
else if (param_no == 17) {
   myPID.serial_type = value ;}
else if (param_no == 18) {
   myPID.roaster = value ;}

ptr = PROFILE_ADDR_PID;

ep.write( ptr, (uint8_t*)&myPID, sizeof( myPID ) );  

}
