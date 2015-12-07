/*
User_defined.pde
This one of the files where user defined infomation goes.  user.h is the other one

The roasting profiles are defined here, and tthe PWM frequency is setup here.
*/

//#include <PWM16.h>          //Added for PWM
/*
struct PID_struc {
  int init_pattern;
	float Pb;
  float I;  
  float D; 
  int PID_factor;
  int starttemp;
  int maxtemp;
  int segment_1;
	int segment_2;
	int seg0_bias;
	int seg1_bias;
	int seg2_bias;
	int seg0_min;
	int seg1_min;
	int seg2_min;
};
*/
//store this information in arduino program memory to store to eeprom

PROGMEM  prog_uint16_t flash_Pb[] = {70};  //Pb constant for PID
PROGMEM  prog_uint16_t flash_I[] = {10};  //I constant for PID
PROGMEM  prog_uint16_t flash_D[] = {25};  //I constant for PID
PROGMEM  prog_uint16_t flash_PID_factor[] = {3};  //I constant for PID
PROGMEM  prog_uint16_t flash_starttemp[] = {200};  //start temp for start of roast
PROGMEM  prog_uint16_t flash_maxtemp[] = {525};  //maxtemp for manual roasts
PROGMEM  prog_uint16_t flash_segment1[] = {2};  //segment 1 starting step
PROGMEM  prog_uint16_t flash_segment2[] = {4};  //segment 2 starting step

/*
PROGMEM  prog_uint16_t flash_seg0_bias[] = {50};  //segment 0 bias
PROGMEM  prog_uint16_t flash_seg1_bias[] = {55};  //segment 0 bias
PROGMEM  prog_uint16_t flash_seg2_bias[] = {60};  //segment 0 bias
PROGMEM  prog_uint16_t flash_seg0_min[] = {20};  //segment 0 min output
PROGMEM  prog_uint16_t flash_seg1_min[] = {25};  //segment 0 min output
PROGMEM  prog_uint16_t flash_seg2_min[] = {30};  //segment 0 min output
*/

///*
PROGMEM  prog_uint16_t flash_seg0_bias[] = {0};  //segment 0 bias
PROGMEM  prog_uint16_t flash_seg1_bias[] = {0};  //segment 0 bias
PROGMEM  prog_uint16_t flash_seg2_bias[] = {0};  //segment 0 bias
PROGMEM  prog_uint16_t flash_seg0_min[] = {0};  //segment 0 min output
PROGMEM  prog_uint16_t flash_seg1_min[] = {0};  //segment 0 min output
PROGMEM  prog_uint16_t flash_seg2_min[] = {0};  //segment 0 min output
//*/

PROGMEM  prog_uint16_t flash_startheat[] = {80};  //heater output until start temp is reached


void pwm_init()
{
// -------------------------- setup PWM Frequency

//Speeds that would work include pwmN128Hz, pwmN60Hz, pwmN50Hz, pwmN32Hz, pwmN30Hz, pwmN16Hz, pwmN8Hz, pwmN4Hz, pwmN2Hz, pwmN1Hz, pwmN2sec,pwmN4sec
//PWM_T = pwmN16Hz;  //set the PWM frequency to 16 Hz

PWM_T = pwmN30Hz;  //set the PWM frequency to 30 Hz
//PWM_T = pwmN60Hz;  //set the PWM frequency to 60 Hz
}

