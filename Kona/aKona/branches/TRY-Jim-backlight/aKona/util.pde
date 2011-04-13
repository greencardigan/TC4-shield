//util.pde
/*
utilities


byte *ptr;
ptr = &in_byte[0];      //set pointer to the input array
 write_rec_profile(prof_ind, ptr);
 void write_rec_profile(int cnt, byte *ptr) {
ep.write( addr, (uint8_t*) ptr, sizeof( myprofile ) );
 
*/


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


