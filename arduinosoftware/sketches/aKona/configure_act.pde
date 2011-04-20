/*
configure_act.pde
configuration/setup routines
*/


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void init_eeprom()
{

int ptr;

myPID.init_pattern = 0x5555;
myPID.Pb = pgm_read_word_near(flash_Pb);
myPID.I = pgm_read_word_near(flash_I);  
myPID.D = pgm_read_word_near(flash_D); 
myPID.PID_factor = pgm_read_word_near(flash_PID_factor);
myPID.starttemp = pgm_read_word_near(flash_starttemp);
myPID.maxtemp = pgm_read_word_near(flash_maxtemp);
myPID.segment_0 = pgm_read_word_near(flash_segment0);
myPID.segment_1 = pgm_read_word_near(flash_segment1);
myPID.segment_2 = pgm_read_word_near(flash_segment2);
myPID.seg0_bias = pgm_read_word_near(flash_seg0_bias);
myPID.seg1_bias = pgm_read_word_near(flash_seg1_bias);
myPID.seg2_bias = pgm_read_word_near(flash_seg2_bias);
myPID.seg0_min = pgm_read_word_near(flash_seg0_min);
myPID.seg1_min = pgm_read_word_near(flash_seg1_min);
myPID.seg2_min = pgm_read_word_near(flash_seg2_min);
myPID.startheat = pgm_read_word_near(flash_startheat);
myPID.serial_type = pgm_read_word_near(flash_serial_type);
myPID.roaster = pgm_read_word_near(flash_roaster);

ptr = PROFILE_ADDR_PID;

ep.write( ptr, (uint8_t*)&myPID, sizeof( myPID ) );

}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void edit_eeprom()
{

int ptr;
int param;
boolean done_4 = false;
boolean pick_4 = false;

int *pt;
pt = &param;      //set pointer to the input array

ptr = PROFILE_ADDR_PID;//init pointer to the start address of the PID info

ep.read( ptr, (uint8_t*)&myPID, sizeof( myPID ) );  

param=0;

while (done_4==false) {
  dsp_function = &display_PID_param_show; //&display_PID_param_select; //function pointer, point to function to display screen for this selection
  done_4 = ( select_something (14, pt) ) ;
  if (done_4 == false) { 
    if (param < 4) {  //first 4 params (0-3) are floats, rest are ints
      edit_flt_param();
      }  
    else {
      edit_param();  
      }
    }  
 }  //end while done

ptr = PROFILE_ADDR_PID;

ep.write( ptr, (uint8_t*)&myPID, sizeof( myPID ) );  


}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void read_eeprom()
{

int ptr;
int param;
boolean done_6 = false;
boolean pick_6 = false;

int *pt;
pt = &param;      //set pointer to the input array

ptr = PROFILE_ADDR_PID;//init pointer to the start address of the PID info

ep.read( ptr, (uint8_t*)&myPID, sizeof( myPID ) );  

param=0;

while (done_6==false) {
  dsp_function = &display_PID_param_show; //function pointer, point to function to display screen for this selection
  done_6 = ( select_something (14, pt) ) ;
 }  //end while done






}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

boolean pick = false;

int act_1;

void configure_act()
{

act_1 = 0;
boolean done_3 = false;
boolean pick_3 = false;

int *pt;
pt = &act_1;      //set pointer to the input array

while (done_3==false) {
  dsp_function = &display_select_con_act; //function pointer, point to function to display screen for this selection
  done_3 = ( select_something (2, pt) ) ;
  if (done_3==false){
    if (act_1 == 0) {
      init_eeprom();	
      }
    else if (act_1 == 1) {
      edit_eeprom();
      }
    else if (act_1 == 2) {
      read_eeprom();
      }
    }  
  }//end while done
 
} // end routine
