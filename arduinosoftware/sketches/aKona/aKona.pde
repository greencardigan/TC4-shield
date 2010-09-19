// a_Kona.pde
// Kona project
#define VERSION 1.04

/*
Revision history
Version 1.04	renamed to a_Kona.pde (arduino side), because creating p_Kona for processing part
put under CM program

Version 1.03	added profile #11 for ROR roasting, and an on the fly mode for ROR control
			adjusted bias and min values

 Written by Randy Tsuchiyama
 This is intended to provide PID type control to roast coffee using an Arduino.
 The author has a hot air (popcorn popper) based roaster, but it should work for other roasters
 by tweaking the PID parameters, and the profile.
 The hardware platform includes the TC4 board, as described in this thread
 http://homeroasters.org/php/forum/viewthread.php?thread_id=1774&rowstart=0
 The TC4 board is an Arduino shield with 4 thermocouple inputs, and two PWM outputs.  
 Only two TC inputs are used by this program.

 This program is based on 
 pBourbon.pde and 16 x 2 LCD
 by Jim Gallt and Bill Welch
 
 thermocouple channel 2 is intended to be Control Temp (CT), and is used to control the PID function
 In my roaster, CT is used for ET, and is monitored where the hot air first contacts the bean mass, at the bottom of the roasting chamber.
 thermocouple channel 1 is intended to be Monitor Temp (MT), and is used for Bean Temp.

 Analog output 1 is (PWM) is used to control the heater SSR           (Arduino pin D9)
 Analog output 2 is (PWM) can be used to control the fan, optional    (Arduino pin D10)

 Analog input 2 is used to read two button switches (plus and escape)
 Digital IO5 is used to read the ENTER button switch
 Digital IO11 is used to read the MINUS button switch

 The program uses the roast profile described below.  There are 10 profiles supported.
 The profiles are stored in flash using PROGMEM, so there is a special step to read the infomation back.
 To change the profiles, you need to edit the profile information below, 
 and reload the program into the Arduino.

 output on serial port:  timestamp, temperature, rise rate in degF per minute

 LCD output is formatted for a 4x20 LCD.  
 output on LCD : 
 line 1
 timestamp, channel 2 temperature (CT), channel 1 temperature (MT)
 
 line 2
 countdown (seconds left in step, CD), Setpoint (SP), MT ROR (MR)
 
 line 3
 Step number (S), P term (P), I term (In), D term (De)
 
 line 4
Heat output (H)
the rest of line for depends on the state of the "roast_mode"
if roast_mode =0, Target Temp (TT) and Delta Temp (DT)
if roast_mode=1, Proportion constant (Pb) and Fanspeed (FS)
if roast_mode=2, Integral Constant (I) and Derivative Constant (D)
 
 Support for Kona Roaster program
 Randy Tsuchiyama

*/

//  ------------------------  include files
#include <Wire.h>
#include <TypeK.h>          
#include <Riser.h>
#include <LiquidCrystal.h>  //LCD library
#include <PWM16.h>          //Added for PWM
#include <avr/pgmspace.h>


//********************************************************************************************************
//***************  SETUP Profiles here   *****************************************************************
//********************************************************************************************************

#define NMAX 14 //  max. number of steps in the profile, note that step 0 is unusable,
//                  so there are really 13 steps available.  Increase this number to add
//                  more steps
#define NAME_SIZE 16 //size of the profile name varibles
#define NO_PROFILES 10  //max number of profiles
#define STARTTEMP 160  // program starts profile when control temp reaches this number

// search profile

//*********** Profile 00 Definition
prog_uchar profile_name_00[] PROGMEM  = {"0Mex Decaf 01   "};  //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_00[] =  {150, 150, 280, 330, 380, 420, 460, 500, 540, 550, 550, 580, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_00[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_00[]= {  0,   0,  20,  27,  35,  40,  45,  50,  50,  50,  50,  50,  50,  50};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_00[] =   { 90,  90,  85,  80,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
//time(min)                                              1  2.5   4   5.5   7    10   13   19      

//*********** Profile 01 Definition
prog_uchar profile_name_01[] PROGMEM  = {"1Brazil Alta4   "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_01[] =  {150, 150, 250, 330, 410, 445, 480, 500, 520, 525, 525, 525, 525, 525};  //temperature
PROGMEM  prog_uint16_t profile_time_01[] =  {  0,   1,  60,  60,  60,  60,  60, 120, 240, 240, 240,   2,   3,   4};  //time per step
PROGMEM  prog_uint16_t profile_offset_01[]= {  0,   0,  20,  25,  35,  45,  45,  50,  55,  55,  55,  55,  55,  55};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_01[] =   { 90,  90,  85,  80,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
//time(min)                                              1    2    3    4    5    7   11   15      

//***********Profile 02 Definition
prog_uchar profile_name_02[] PROGMEM  = {"2Kona01         "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_02[] =  {150, 150, 150, 250, 250, 410, 480, 520, 550, 560, 560, 560, 560, 560};  //temperature
PROGMEM  prog_uint16_t profile_time_02[] =  {  0,   1,   1,  60,   1, 120, 120, 240, 240, 480, 240,   1,   1,   1};  //time per step
PROGMEM  prog_uint16_t profile_offset_02[]= {  0,   0,   0,  20,  20,  35,  45,  50,  50,  50,  50,  50,  50,  50};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_02[] =   { 90,  90,  90,  85,  85,  80,  75,  70,  70,  70,  70,  70,  70,  70}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
//time(min)                                                   1         4    7   13   16   19      

//***********Profile 03 Definition
prog_uchar profile_name_03[] PROGMEM  = {"3Eth hr04       "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_03[] =  {150, 150, 250, 330, 410, 445, 480, 500, 520, 525, 525, 525, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_03[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 240, 240, 240,   4,   5,   6};  //time per step
PROGMEM  prog_uint16_t profile_offset_03[]= {  0,   0,   0,  10,  20,  35,  45,  55,  60,  60,  60,  60,  60,  60};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_03[] =   { 75,  75,  70,  70,  65,  60,  55,  55,  50,  50,  50,  50,  50,  50}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,
//time(min)                                             1    2.5  4   5.5   7    10   14   18
//ramp                                                      53    53   23   23  6.7   5   1.3                        

//***********Profile 04 Definition
prog_uchar profile_name_04[] PROGMEM  = {"4Eth hr03       "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_04[] =  {200, 200, 200, 250, 250, 410, 480, 500, 520, 525, 525, 580, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_04[] =  {  0,   1,   1,  60,   1, 240, 180, 240, 180, 240, 240,   5,   6,   7};  //time per step
PROGMEM  prog_uint16_t profile_offset_04[]= {  0,   0,   0,  10,  20,  35,  45,  50,  55,  60,  60,  60,  60,  60};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_04[] =   { 90,  90,  90,  85,  85,  80,  75,  70,  70,  70,  70,  70,  70,  70}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
//time(min)                                                   1         4    7   13   16   19      

//***********Profile 05 Definition
prog_uchar profile_name_05[] PROGMEM  = {"5Eth hr05       "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_05[] =  {200, 200, 250, 330, 410, 445, 480, 500, 520, 525, 540, 540, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_05[] =  {  0,   1,  60,  90,  90,  60,  60, 120, 240, 240, 240,   4,   5,   6};  //time per step
PROGMEM  prog_uint16_t profile_offset_05[]= {  0,   0,   0,  10,  20,  35,  45,  55,  60,  60,  60,  60,  60,  60};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_05[] =   { 90,  90,  85,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,
//time(min)                                             1    2.5  4    5    6     8   14   18      
//ramp                                                      53    53   35   35   10   5   1.3     

//***********Profile 06 Definition
prog_uchar profile_name_06[] PROGMEM  = {"6Eth hr06       "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_06[] =  {200, 200, 250, 330, 410, 445, 480, 500, 520, 525, 540, 540, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_06[] =  {  0,   1,  60,  90,  90,  60,  60, 120, 240, 240, 240,   4,   5,   6};  //time per step
PROGMEM  prog_uint16_t profile_offset_06[]= {  0,   0,   0,  10,  20,  35,  45,  55,  60,  60,  60,  60,  60,  60};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_06[] =   { 90,  90,  85,  80,  75,  70,  65,  60,  60,  55,  55,  55,  55,  55}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,
//time(min)                                             1    2.5  4    5    6     8   14   18      
//ramp                                                      53    53   35   35   10   5   1.3     

//***********Profile 07 Definition
prog_uchar profile_name_07[] PROGMEM  = {"3Eth hr07      "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_07[] =  {200, 200, 250, 330, 410, 445, 480, 500, 520, 525, 525, 525, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_07[] =  {  0,   1,  60,  90,  90,  40,  40,  60, 240, 240, 240,   4,   5,   6};  //time per step
PROGMEM  prog_uint16_t profile_offset_07[]= {  0,   0,   0,  10,  20,  35,  45,  55,  60,  60,  60,  60,  60,  60};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_07[] =   { 75,  75,  70,  70,  65,  60,  55,  55,  50,  50,  50,  50,  50,  50}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,
//time(min)                                             1    2.5  4     5   6.5  7.5 11.5 15.5
//ramp                                                      53    53   23   23  6.7   5   1.3                        

//***********Profile 08 Definition
prog_uchar profile_name_08[] PROGMEM  = {"8temp 00        "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_08[] =  {200, 200, 200, 280, 280, 380, 455, 540, 550, 550, 550, 580, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_08[] =  {  0,   1,   1,  60,   1, 180, 180, 360, 180, 180, 240,   9,  10,  11};  //time per step
PROGMEM  prog_uint16_t profile_offset_08[]= {  0,   0,   0,  20,  20,  25,  30,  35,  40,  40,  40,  40,  40,  40};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_08[] =   { 90,  90,  90,  85,  85,  80,  75,  70,  70,  70,  70,  70,  70,  70}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
//time(min)                                                   1         4    7   13   16   19      

//***********Profile 09 Definition
prog_uchar profile_name_09[] PROGMEM  = {"9 34567890123456"};    //Max string size is 16 characters
PROGMEM  prog_uint16_t profile_temp_09[] =  {200, 200, 200, 280, 280, 380, 455, 540, 550, 550, 550, 580, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_09[] =  {  0,   1,   1,  60,   1, 180, 180, 360, 180, 180, 240,  10,  11,  12};  //time per step
PROGMEM  prog_uint16_t profile_offset_09[]= {  0,   0,   0,  20,  20,  25,  30,  35,  40,  40,  40,  40,  40,  40};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_09[] =   {100, 100, 100,  10,  90,  90,  75,  60,  60,  60,  60,  60,  60,  60}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
//time(min)                                                   1         4    7   13   16   19      

// arrays to store the profile information during the roast
char Profile_Name_buffer[NAME_SIZE];   
int Temp_array[NMAX];   
int Time_array[NMAX];   
int Offset_array[NMAX];   
int Speed_array[NMAX]; 

int step = 0;    // step of the roast

// search pid init

//****************************************************************************************************
//                  PID controller parameters and setup
//****************************************************************************************************
float PID_setpoint;    // parameters for PID
float delta_temp;
float target_temp;
int output = 0;

// search PID01
float Pb = 70;     //Proportional Constant  
float I = 10;        //Integral Constant
float D = 25;        //Derivative Constant


int PID_factor = 3;   // scale down the PID output by this factor (divide by it)  old was 2.4

int roast_mode;

float Proportion = 0;   //variable to store Proportional term
float Integral = 0;     //variable to store Integral term
float Derivative = 0;   //variable to store Derivative term

int PID_error[11];      //array to save last 10 PID error values, used to calculate intergral term
int error_ptr = 0;

int PID_bias;
int PID_min;
int PID_offset;

int segment = 0;    // segment of the roast, some parameters will change depending on the segment we are in.
#define NO_SEGMENTS 2 // currently support 3 roast segments

boolean SEG1_flag = false;  //flag to tell if segment 1 has started
boolean SEG2_flag = false;  //flag to tell if segment 2 has started

// define the segment boundaries
#define SEGMENT_1 3 // Segment 1 starts when the roast step is 3
#define SEGMENT_2 5 // Segment 2 starts when the roast step is 5

// define the segment based parameters
//PID output will be centered around the bias value, all corrections will be to this value.
#define SEG0_BIAS 40   //Bias value for the early parts of the roast
#define SEG1_BIAS 45   //Bias value for the middle parts of the roast
#define SEG2_BIAS 45   //Bias value for the later parts of the roast
//min PID output value.
#define SEG0_MIN 20   //minimum value for the early parts of the roast
#define SEG1_MIN 25   //minimum value for the middle parts of the roast
#define SEG2_MIN 30   //minimum value for the later parts of the roast


// -------------------------- PWM Frequency
unsigned int PWM_T = pwmN16Hz;  //set the PWM frequency to 16 Hz

//Speeds that would work include pwmN8Hz, pwmN4Hz, pwmN2Hz, pwmN1Hz, pwmN2sec,pwmN4sec
//it does suppport faster speeds, but I don't think it would make sense to try to switch faster then 16 hz

PWM16 pwmOut;

// ------------------------ conditional compiles or constants

#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define MCP9800_DELAY 100 // sample period for MCP9800
#define MAGIC_NUMBER 960 // not quite 1000 to make up for processing time
#define RES_11      // resolution on ambient temp chip
#define NAMBIENT 12  // number of ambient samples to be averaged
#define CFG CFG8  // select gain = 8 on ADC
#define NCHAN 2   // number of TC input channels
#define BAUD 57600  // serial baud rate
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output
// fixme This value should be user selectable
#define NSAMPLES 10 // samples used for moving average calc for temperature

// ---------------------------- calibration of ADC and ambient temp sensor
// fixme -- put this information in EEPROM
#define CAL_OFFSET  ( 0 )  // microvolts
#define CAL_GAIN 1.0035
#define TEMP_OFFSET ( 1.5 );  // Celsius offset

// -------------- ADC configuration

#define ADC_RDY 7  // ready bit
#define ADC_C1  6  // channel selection bit 1
#define ADC_C0  5  // channel selection bit 0
#define ADC_CMB 4  // conversion mode bit (1 = continuous)
#define ADC_SR1 3  // sample rate selection bit 1 (11 = 18 bit)
#define ADC_SR0 2  // sample rate selection bit 0
#define ADC_G1  1  // gain select bit 1
#define ADC_G0  0  // gain select bit 0

#define CFG1 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) ) // 18 bit, gain = 1
#define CFG2 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G0) ) // 18 bit, gain = 2 
#define CFG4 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) ) // 18 bit, gain = 4 
#define CFG8 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) | _BV(ADC_G0) ) // 18 bit, gain = 8

#define A_BITS9  B00000000
#define A_BITS10 B00100000
#define A_BITS11 B01000000
#define A_BITS12 B01100000

#define BITS_TO_uV 15.625  // LSB = 15.625 uV

// -------------------- MCP9800 configuration
#ifdef RES_12
#define A_BITS A_BITS12
#endif
#ifdef RES_11
#define A_BITS A_BITS11
#endif
#ifdef RES_10
#define A_BITS A_BITS10
#endif
#ifdef RES_9
#define A_BITS A_BITS9
#endif

// --------------------------
#define A_ADC 0x68
#define A_AMB 0x48

// --------------------------------------------------------------------------------

// define sub routines here

void get_samples();
void get_ambient();
void init_ambient();
void avg_ambient();
void blinker();
void logger();
int wait_button(void);
int get_button(void);
void display_profile();
void roast_mode_select();
void display_roast();


// global variables
int countdown;    // count down seconds till end of step
float slope;      // setpoint slope
float ROR;		// Rate of rise for manual roasting
int serialTime;   // determine step
float ct;         // Control temp, input from t2
float ct_old;     // Control temp from previous cycle/second
float mt;         // Bean temp, based on t1
float timestamp = 0;
float startTime = 0;  //time when roasts starts, use to offset global time to display roast time
float RoRmt,RoRct,t1,t2;
float tod;
int heat, fan;
int FanSpeed;

// variables for manual ROR roasting
float ramp_st_temp=0;      //saves the starting temp for current ramp step, reset to current time whenever ROR is changed
float ramp_st_time;       //saves the starting time for current ramp step, reset to current time whenever ROR is changed
boolean ror_change = false;
boolean last_button = false;

// updated at intervals of DELAY ms
int32_t samples[NCHAN];
int32_t temps[NCHAN];
int32_t ambs[NAMBIENT];

int32_t ambient = 0;
int32_t amb_f = 0;
int32_t sumamb = 0;
int32_t avgamb = 0;

int adc_delay;

Riser rise1( NSAMPLES );
Riser rise2( NSAMPLES );
Riser rise3( NSAMPLES );
Riser rise4( NSAMPLES );

//*******************************************************************************************************
//
// Parameters that are based on the hardware, and how it's setup
//
//*******************************************************************************************************

// search LCD init
//*********LCD SETUP

// ------------------ LCD settings for homeroaster wiring
#define RS 2
#define ENABLE 4
#define DB4 7
#define DB5 8
#define DB6 12
#define DB7 13
LiquidCrystal lcd( RS, ENABLE, DB4, DB5, DB6, DB7 );

int ledPin = 13;


// -------------------------- output connections from TC4 to Arduino
// not used by the program
#define FANPIN 10        // fan motor connected to pwm pin 10
#define HEATPIN 9        // heating coil SSR connected to pin 9


// search button init
// -------------------------- Settings and Values for Button switches and button wiring
#define BUTTON         2       // read ESC and PLUS switches on analog input port 2
#define ENTERPIN      11       // read ENTER switch on digital i/o 11
#define MINUSPIN       5       // read MINUS switch on digital i/o 5
#define ANYKEY       640       // value to decide if anykey is pushed
#define PLUS_VALUE   710       // value to decide if Plus is pushed
#define ESC_VALUE    860       // value to decide if ESC is pushed
#define DEBOUNCE     350       // debounce time

#define NOBUTTON 0       // set to this value if no valid switch push detected
#define MINUS    1       // set to this value if Minus is pushed
#define PLUS     2       // set to this value if Plus is pushed
#define ENTER    3       // set to this value if ENTER is pushed
#define ESC      4       // set to this value if ESC is pushed

int buttonValue = 0;  // variable to store the analog input value coming from the switches


// search PID
//************************************************************************
// ------------------------- PID routine -------------------------------
//************************************************************************
//logic for calculating the PID output
//
//  error = setpoint - actual temp + offset
//  Proportional term = error/Pb, where Pb is Proportional Band
//  integral = integral + (error*dt)
//  derivative = (error - previous_error)/dt
//  output = (Kp*error) + (Ki*integral) + (Kd*derivative)
//  previous_error = error

//  NOTE: Assume we are running once per second, so dt=1

int PID()
{
//PID_setpoint is the target temperature
//slope (global variable) is the change in temperature in one sec, so it is the D term
//P is Pb
//I is Ki
//D is Kd 

//define and initialize local variables
  int error = 0;
  int previous_error = 0;
  int Sum_errors = 0;
  int out = 0;

// error equals setpoint - control temp + offset, where offset is a fudge factor to compensate for any temp tracking errors.
// note that offset is dependent on the step of the roast

error = PID_setpoint - ct + Offset_array[step];

// technically, intergral should be the sum of all errors, but I am only summing the recent errors, and subtract out errors prior to that.
//logic to subtract out old error value from integral 
error_ptr++;
if (error_ptr > sizeof(error_ptr - 1)) {    //check to see if pointer is past the end of the array
  error_ptr = 0;  //reset index to beginning of array
  }
Sum_errors = Sum_errors - PID_error[error_ptr];  //remove oldest error value from Sum_errors
PID_error[error_ptr] = error; //then add current error to error array

Sum_errors = Sum_errors + error;  //Sum_errors is sum of the latest error values


// check to see what roast segment we are in
// bias and min vary with roast segment, so I am changing things depending on the segment we are in.
if (segment <= NO_SEGMENTS) {
   if (SEG1_flag == false)  {
      if (step == SEGMENT_1) {
         PID_bias = SEG1_BIAS;
         PID_min = SEG1_MIN;
         SEG1_flag = true;
         segment++;
         }
      }
   if (SEG2_flag == false)  {
      if (step == SEGMENT_2) {
         PID_bias = SEG2_BIAS;
         PID_min = SEG2_MIN;
         SEG2_flag = true;
         segment++;
         }
      }
   }

Proportion = error/Pb*100; 
Integral = (I * Sum_errors)/Pb;
Derivative = D * (ct-ct_old)/Pb;

out = ((Proportion + Integral - Derivative)/PID_factor) + PID_bias;

//Make sure PID result is not out of bounds, set it to boundry limits of pid_min or 100 if it is
if (out > 100) {
   out = 100;
   }
if (out < PID_min) {
   out = PID_min;   //minimum output 
   }

output = out;
}

// ------------------------------------------------------------------
// routine to read in thermocouple data and send to USB port

void logger()
{
  int i;

  // print timestamp
  tod = millis() * 0.001 - startTime;
  Serial.print(tod, DP);

  // print ambient
  Serial.print(",");
  Serial.print( C_TO_F(avgamb * 0.01), DP );
   
  // print temperature, rate for each channel.  
//Ch 1 is MT
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print(",");
    Serial.print( t1 = 0.01 * temps[i], DP );  //Get temp from channel 1
    Serial.print(",");
    Serial.print( RoRmt = rise1.CalcRate( tod, 0.01 * temps[i++] ), DP );  //calculate Rate of change for ch 1, mt
//note that only RoRmt is displayed on the PC graph
    mt = t1;  //set bean temp to ch 1 temp
  };
  
//Ch 2 is Control Temp (ct)
  if( NCHAN >= 2 ) {
    Serial.print(",");
    Serial.print( t2 = 0.01 * temps[i], DP );  //Get temp from channel 2
    Serial.print(",");
    Serial.print( RoRct = rise2.CalcRate( tod, 0.01 * temps[i++] ), DP );  //calculate Rate of change for ch 2, ct
    ct = t2;  //set control temp to ch 2 temp
  };
  
  //send setpoint to serial port for saving to logfile
  Serial.print(",");
  Serial.print( PID_setpoint, DP );  //send setpoint, to compare setpoint to temps

  Serial.print(",");
  Serial.print( step );  //send setpoint, to compare setpoint to temps

  Serial.print(",");
  Serial.print( countdown );  //send setpoint, to compare setpoint to temps

  Serial.println();
   
  
};

// --------------------------------------------------------------------------
void get_samples()
{
  int stat;
  byte a, b, c, rdy, gain, chan, mode, ss;
  int32_t v;
  TC_TYPE tc;
  float tempC;

  Wire.requestFrom(A_ADC, 4);
  a = Wire.receive();
  b = Wire.receive();
  c = Wire.receive();
  stat = Wire.receive();

  rdy = (stat >> 7) & 1;
  chan = (stat >> 5) & 3;
  mode = (stat >> 4) & 1;
  ss = (stat >> 2) & 3;
  gain = stat & 3;
  
  v = a;
  v <<= 24;
  v >>= 16;
  v |= b;
  v <<= 8;
  v |= c;
  
  // convert to microvolts
  v = round(v * BITS_TO_uV);

  // divide by gain
  v /= 1 << (CFG & 3);
  v += CAL_OFFSET;  // adjust calibration offset
  v *= CAL_GAIN;    // calibration of gain
  samples[chan] = v;  // units = microvolts

  // convert mV to temperature using ambient temp adjustment
  tempC = tc.Temp_C( 0.001 * v, avgamb * 0.01 );
  tempC += TEMP_OFFSET;

  // convert to F and multiply by 100 to preserve precision
  v = round( C_TO_F( tempC ) * 100 );
  temps[chan] = v;

  if( NCHAN == ++chan ) chan = 0;

  Wire.beginTransmission(A_ADC);
  Wire.send(CFG | (chan << 5) ); // setup the register for next conversion
  Wire.endTransmission();
}

// ---------------------------------------------------------------------
void get_ambient()
{
  byte a,b;
  int32_t v,va,vb;

  Wire.beginTransmission(A_AMB);
  Wire.send(0); // point to temperature reg.
  Wire.endTransmission();
  Wire.requestFrom(A_AMB, 2);
  a = Wire.receive();
  b = Wire.receive();
  va = a;
  vb = b;
  
#ifdef RES_12
// 12-bit code
  v = ( ( va << 8 ) +  vb ) >> 4;
  v = ( 100 * v ) >> 4;
#endif
#ifdef RES_11
// 11-bit code
  v = ( ( va << 8 ) +  vb ) >> 5;
  v = ( 100 * v ) >> 3;
#endif
#ifdef RES_10
// 10-bit code
  v = ( ( va << 8 ) +  vb ) >> 6;
  v = ( 100 * v ) >> 2;
#endif
#ifdef RES_9
// 9-bit code
  v = ( ( va << 8 ) +  vb ) >> 7;
  v = ( 100 * v ) >> 1;
#endif

 ambient = v;  
}

// --------------------------------------------------------------------
void init_ambient() {
  int i;
  int n;
  n = NAMBIENT;
  if( NAMBIENT < 1 ) n = NAMBIENT; 
  for( i = 0; i < n; i++ ) {
    get_ambient();
    delay( MCP9800_DELAY );
    sumamb += ambient;
    ambs[i] = ambient;
  }
}

// ----------------------------------------------------------------------
void avg_ambient() {
  int i;
  if( NAMBIENT <= 1 ) 
    avgamb = ambient;
  else {
    sumamb += ambient - ambs[0];  // delete oldest value
    for( i = 0; i < NAMBIENT-1; i++ ) {
      ambs[i] = ambs[i+1];
    }
   ambs[NAMBIENT-1] = ambient;
   avgamb = sumamb / NAMBIENT;
  }
}  
  
// ---------------------------------------------------------------------
void blinker()
{
  static char on = 0;
  if (on) {
    digitalWrite(ledPin, HIGH);
  } else {
      digitalWrite(ledPin, LOW);
  }
  on ^= 1;
}

// ------------------------------------------------------------------------

//this routine waits for the user to push a button switch, and then returns the button switch value

int wait_button (void){
  
int read_button;
int button_pushed;
boolean pushed;

pushed = false;
read_button =0;
while (pushed == false) { // wait for a button to be pushed
	read_button = analogRead (BUTTON);  
	if (read_button > ANYKEY) { 
		read_button = analogRead (BUTTON);  
		if (read_button > ESC_VALUE) {  //esc key was pushed
			button_pushed = ESC;
			pushed = true;
			}
		else if (read_button > PLUS_VALUE) {      //plus key pushed, it is lowest one
			button_pushed = PLUS;
			pushed = true;
			}
		}   
	if (digitalRead (ENTERPIN) == 1) {  //see if the Enter button was pushed
		button_pushed = ENTER;
		pushed = true;
		}
	if (digitalRead (MINUSPIN) == 1) {  //see if the Minus button was pushed
		button_pushed = MINUS;
		pushed = true;
		}
	}   
delay (DEBOUNCE);
return button_pushed;  
}
// ------------------------------------------------------------------------
//this routine sees if a button was pushed, returns the button value

int get_button (void){
  
int read_button;
int button_pushed;
boolean pushed;

read_button =0;
button_pushed = NOBUTTON;
read_button = analogRead (BUTTON);  
if (read_button > ANYKEY) { 
    read_button = analogRead (BUTTON);  
    if (read_button > ESC_VALUE) {  //esc key was pushed
		button_pushed = ESC;
        }
    else if (read_button > PLUS_VALUE) {  //plus key pushed, it is lowest one
        button_pushed = PLUS;
        }
    }   
if (digitalRead (ENTERPIN) == 1) {  //see if the Enter button was pushed
    button_pushed = ENTER;
    }
if (digitalRead (MINUSPIN) == 1) {  //see if the Minus button was pushed
    button_pushed = MINUS;
    }
return button_pushed;  
}

// ------------------------------------------------------------------------
// this routine displays the profile name on the LCD

void display_profile()
{
int i;
lcd.clear();
lcd.home();
lcd.print(" Profile name");
lcd.setCursor(0,1);
for (i = 0; i < 16; i++) {   //send name of this profile to display
	lcd.print(Profile_Name_buffer[i]);
	}
}

// ------------------------------------------------------------------------
// this routine selects the roast mode for on the fly changes during the roast

void roast_mode_select()
{

boolean picked = false;

roast_mode=0;
while (picked == false) {
	lcd.clear();
	lcd.home();
	lcd.print("Select roast mode");
	lcd.setCursor(0,1);
	lcd.print("0=temp,fs; 1=Pb,fs");
	lcd.setCursor(0,2);
	lcd.print("2=I,D;  3=ror,fs");
	lcd.setCursor(0,3);
	lcd.print("mode = ");
	lcd.print(roast_mode);
	buttonValue = wait_button();       
	if (buttonValue == ESC) {}
	else if (buttonValue == PLUS) {
		if (roast_mode == 3) {roast_mode=0;}
		else {roast_mode++;}
		}
	else if (buttonValue == MINUS) {
		if (roast_mode == 0) {roast_mode=3;}
		else {roast_mode--;} 
		}
	else if (buttonValue == ENTER) {
		picked = true;
		}
	}
    
}

// ------------------------------------------------------------------------
// this routine displays the information on the LCD during the roast

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
lcd.print(tmp/60);     //1-2
lcd.print(":");          // 3
lcd.print(tmp%60);     //4-5

// format and display ct
tmp = round( ct );
if( tmp > 999 ) tmp = 999;
lcd.setCursor(5,0);    
lcd.print (" CT:" );  //6-9
lcd.print (tmp);       //10-12

//format and display mt
tmp = round(mt);
if( tmp > 999 ) tmp = 999;
else if( tmp < -999 ) tmp = -999;   
lcd.print (" MT:");    //13-16
lcd.print(tmp);     //17-19

//Row 2
lcd.setCursor(0,1);
lcd.print("CD");          //1-2
lcd.print(countdown);     //3-5 countdown is int
  
lcd.setCursor(6,1);

//format and display the setpoint
lcd.print("SP:");          //7-9
dsp_temp = PID_setpoint + 0.5;  //set up setpoint to round off
dsp_int = dsp_temp;              //round off setpoint to type int to display it
lcd.print(dsp_int);  //10-12

//Format mt RoR
tmp = round( RoRmt);
if( tmp > 99 ) tmp = 99;
else if( tmp < -99 ) tmp = -99; 
lcd.print (" MR:"); //13-16
lcd.print(tmp);     //17-19

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



//Row 4
lcd.setCursor(0,3);
lcd.print("H:");         //1-2
if (heat >= 100) {tmp = 99;}
else {tmp = heat;}
lcd.print(tmp);         //3-4

switch (roast_mode){
	case (0):  //can change temp and time on the fly, so display associated params
		lcd.print( " TT:");      //5-8
		dsp_int = target_temp;          //round off setpoint to type int to display it
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

} // end routine

// ------------------------------------------------------------------------
// this selects the profile to run
void select_profile()
{
boolean picked = false;
int cntr = 0;
int ind = 0;


while (picked == false) {  //do until a profile is picked

// check if profile 0 is picked
	buttonValue = 0;
	
	switch (cntr){
		case (0):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_00 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_00 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_00 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_00 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_00 + ind);
					}	
				}
			else if (buttonValue == PLUS) {
				cntr++;
				}
			else {
				cntr=(NO_PROFILES - 1); 
				}     
            break;
			   
// check if profile 1 is picked
		case (1):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_01 + ind);
			}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_01 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_01 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_01 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_01 + ind);
					}
				}
			else if (buttonValue == PLUS) { cntr++; }
			else { cntr--; }        
	        break;
			   
	//see if profile 02
		case (2):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_02 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_02 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_02 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_02 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_02 + ind);
					}
				}
			else if (buttonValue == PLUS) { cntr++;}
			else { cntr--; }        
            break;
			
	//see if profile 03
		case (3):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_03 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {
				}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_03 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_03 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_03 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_03 + ind);
					}
				}
			else if (buttonValue == PLUS) { cntr++; }
			else {cntr--; }      
            break;            

	//see if profile 04
		case (4):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_04 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {
				}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_04 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_04 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_04 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_04 + ind);
					}
				}
			else if (buttonValue == PLUS) {	cntr++;	}
			else { cntr--; }        
            break;
			
	//see if profile 05
		case (5):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_05 + ind);
			}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_05 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_05 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_05 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_05 + ind);
					}
				}
			else if (buttonValue == PLUS) { cntr++; }
			else { cntr--; }        
            break;
			
	//see if profile 06
		case (6):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_06 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_06 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_06 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_06 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_06 + ind);
					}
				}
			else if (buttonValue == PLUS) {   cntr++;        }
			else { cntr--;        }        
			break;
			
	//see if profile 07
		case (7):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_07 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {  }
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_07 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_07 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_07 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_07 + ind);
					}
				}
			else if (buttonValue == PLUS) {cntr++;   }
			else { cntr--; }        
            break;
			
	//see if profile 08
		case (8):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_08 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {    }
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_08 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_08 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_08 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_08 + ind);
					}
				}
			else if (buttonValue == PLUS) {  cntr++;  }
			else { cntr--; }        
            break;

	//see if profile 09
		case (9):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_09 + ind);
				}
			display_profile();
			buttonValue = wait_button();       
			if (buttonValue == ESC) {}
			else if (buttonValue == ENTER) {
				picked = true;
				for (ind = 0; ind < NMAX; ind++) {  
					Temp_array[ind] = pgm_read_word_near(profile_temp_09 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_09 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_09 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_09 + ind);
					}
				}
			else if (buttonValue == PLUS) { cntr=0; } //wraparound 
			else { cntr--; }        
            break;
			
	// Make sure cntr does not get messed up
		default:   
			cntr = 0;
			break;
		} // end of switch-case 
	} // end of while picked is false

}

//*****************************************************************************************************
// 
// MAIN
//
//******************************************************************************************************

//************************  Initialization section, only runs once, at beginning of program

void setup()
{
  byte a;

pinMode(ledPin, OUTPUT);
pinMode (ENTERPIN, INPUT);
pinMode (MINUSPIN, INPUT);

// SEARCH LCD 02
// ******************  Setup LCD code for size of LCD
//  lcd.begin(16, 2); //use for 2x16 LCD
lcd.begin(20, 4);  //use for 4x20 LCD

  
// want delay between sample sets to be at least 1 second
adc_delay = MAGIC_NUMBER / NCHAN;
if( adc_delay < MIN_DELAY ) adc_delay = MIN_DELAY ;
Serial.begin(BAUD);

while ( millis() < 1000) {
	blinker();
    delay(100);
	}

//  Serial.println(msg);
Serial.print("# time,ambient,T0,rate0");
if( NCHAN >= 2 ) Serial.print(",T1,rate1");
Serial.print(",Setpoint,Step,Countdown");
Serial.println();
 
while ( millis() < 3000) {
	blinker();
    delay(100);
	}

Wire.begin();

// configure mcp3424
Wire.beginTransmission(A_ADC);
Wire.send(CFG);
Wire.endTransmission();

// configure mcp9800.
Wire.beginTransmission(A_AMB);
Wire.send(1); // point to config reg
Wire.send(A_BITS); 
Wire.endTransmission();

// see if we can read it back.
Wire.beginTransmission(A_AMB);
Wire.send(1); // point to config reg
Wire.endTransmission();
Wire.requestFrom(A_AMB, 1);
a = 0xff;
if (Wire.available()) {
a = Wire.receive();
}
if (a != A_BITS) {
Serial.println("# Error configuring mcp9800");
} else {
Serial.println("# mcp9800 Config reg OK");
}

// initialize ambient temperature ring buffer
init_ambient();

//Set PWM output frequency
pwmOut.Setup( PWM_T );

//Setup initial PID parameters for bias and min output
PID_bias = SEG0_BIAS;
PID_min = SEG0_MIN;

lcd.clear();
lcd.home();
lcd.print("a_Kona V");
lcd.print (VERSION);
delay (1500);

select_profile();

roast_mode_select();

           
} // end of setup

//--------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
// START OF MAIN PROGRAM LOOP-----------------------------------------------------------------
void loop()
{
float idletime;

// limit sample rate to once per second
//while ( (millis() % 1000) != 0 ) ;  

timestamp = float(millis()) / 1000.;

buttonValue = 0;  //reset button pushed to not pushed

get_ambient();
avg_ambient();
for (int i=0; i<NCHAN; i++) {
get_samples();
blinker();
delay( adc_delay );
}
logger();   //send data to Com port and LCD, get CT and MT.


// go directly to sp during step 0
if (step == 0) {
	PID_setpoint = STARTTEMP;           // for step 0, target temp is STARTTEMP
	ROR = 30;                          // intialize ROR, for manual ror roasts
	FanSpeed = 80;                      // for manual ror roasts 
	serialTime = millis () / 1000;      // for manual ror roasts
	if (ct >= (PID_setpoint - 10) ) {      // if et is within 10 deg of this setpoint, then start roast
		countdown=-1;
		startTime = millis() * 0.001;  //use to reset displayed time to the start of roast time
		ramp_st_time = startTime;         //for manual ROR roasting, set current time as the start time for first ramp
		ramp_st_temp = ct;	               //for manual ROR roasting, set start temp as current Control Temp
		}   // start step 1 when setpoint is reached
	}

if (roast_mode == 3) {  // if roast_mode is 3, then perform manual roast using ROR
	if (countdown == -1) {
			step = 1;                     //get out of step 0 mode logic
			countdown = 0;                //reset counter
			PID_setpoint =ct;             //change setpoint to current control temp, for now
		}
	else  {
		countdown = (millis() * 0.001) - ramp_st_time; //for manual ROR roasting, using countdown for how long at this ramp rate
		slope = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
		PID_setpoint = ramp_st_temp + (slope * countdown);  //current target temp is temp at start of ramp plus (slope*time)
		}
	}
else {  //automatic roast per profile
	// if countdown ends, start new step and count down
	if (countdown < 0) {
		step = step + 1;
		serialTime = millis () / 1000;
		if (target_temp > (Temp_array [step])) {Temp_array [step] = target_temp;}
		serialTime = serialTime + (Time_array [step]);
		delta_temp =  ( (Temp_array [step]) - (Temp_array [(step - 1)]) );
		slope =  (delta_temp / (Time_array [step]));
		target_temp = Temp_array [step];
		FanSpeed = Speed_array [step];
		}
	// check to see if at the end of the roast profile
	if (step > NMAX) {
		pwmOut.Out( 0,100 ); //shut off heater, set fan speed to full
		lcd.clear();
		lcd.home();
		lcd.print("Roast Complete");
		lcd.setCursor(0,1);
		lcd.print("  turn off");
		lcd.setCursor(0,2);
		lcd.print("  when cool");
		while (1>0) {}  //wait forever, until power down
		}
	// determine PID setpoint based on slope (ramp) and time
	if (step > 0) {
		countdown = serialTime - ((millis ())/1000);
		PID_setpoint = Temp_array [(step - 1)] + (slope *  ((Time_array [step]) - countdown));
		}
	}
// PID control, adjust heater output 
PID();
heat = output;

if (FanSpeed > 100) {FanSpeed = 100;}  //Make sure FanSpeed is within top limit
else if (FanSpeed < 40) {FanSpeed = 40;}

//write new PID value to pwm pins
pwmOut.Out( heat, FanSpeed );

//remember old ct for next cycle
ct_old = ct;


// for on the fly changes

switch (roast_mode){
	case (0):  //change target temp for this ramp, or fanspeed for this ramp for this case
		buttonValue = get_button();    
		if (buttonValue == PLUS) { // check if plus was pushed, increase target temp if it was
			 delta_temp =  (PID_setpoint + 5) - ct;  //new delta temp is endtemp + 5 - current control temp
			 slope =  (delta_temp / countdown);
			 target_temp = target_temp + 5;
			 }
		else if (buttonValue == MINUS) { //minus key was pushed, decrease target temp if it was
			 delta_temp =  (PID_setpoint - 5) - ct;
			 slope =  (delta_temp / countdown);
			 target_temp = target_temp - 5;
			 }
		else if (buttonValue == ENTER) { //minus key was pushed, dec fanspeed if it was
			FanSpeed = FanSpeed - 2;
			}
		else if (buttonValue == ESC) { //minus key was pushed, inc fanspeed if it was
			FanSpeed = FanSpeed + 2;
          		}
		buttonValue = 0;
        break;
                	
	case (1):  //flyptr1 is Pb and flyptr3 is FanSpeed for this case
		buttonValue = get_button();    
		if (buttonValue == PLUS) { // check if plus was pushed
			Pb = Pb + 10;
			}
		else if (buttonValue == MINUS) {  //minus key was pushed
			Pb = Pb - 10;
			}
		else if (buttonValue == ENTER) { //minus key was pushed, dec fs if it was
			FanSpeed = FanSpeed - 2;
			}
		else if (buttonValue == ESC) { //minus key was pushed, inc fs if it was
			FanSpeed = FanSpeed + 2;
			}
		buttonValue = 0;
        break;
                
	case (2):  //flyptr1 is I and flyptr2 is D for this case
		buttonValue = get_button();    
		if (buttonValue == PLUS) { // check if plus was pushed
			I = I + 1;
			}
		else if (buttonValue == MINUS) {  //minus key was pushed
			I = I - 1;
			}
		else if (buttonValue == ENTER) { //minus key was pushed, dec D if it was
			D = D - 1;
			}
		else if (buttonValue == ESC) { //minus key was pushed, inc D if it was
			D = D + 1;
			}
		buttonValue = 0;
        break;
	case (3):  //manual roast mode, flyptr1 is ct ROR and flyptr2 is FanSpeed for this case
		buttonValue = get_button();    
		if (buttonValue == PLUS) { // check if plus was pushed
			if (last_button == true) {
				ROR = ROR + 5;
				ramp_st_time = millis() * 0.001;     //set new start time since ramp change
				ramp_st_temp = PID_setpoint;     //set new start temp since ramp change
  //reset counter since ROR is changing
				}
			else {
				ROR = ROR + 1;
				ramp_st_time = millis() * 0.001;     //set new start time since ramp change
				ramp_st_temp = PID_setpoint;     //set new start temp since ramp change
				}
			last_button = true;
		}	
		else if (buttonValue == MINUS) {  //minus key was pushed
			if (last_button == true) {
				ROR = ROR - 5;
				ramp_st_time = millis() * 0.001;     //set new start time since ramp change
				ramp_st_temp = PID_setpoint;     //set new start temp since ramp change
				}
			else {
				ROR = ROR - 1;
				ramp_st_time = millis() * 0.001;     //set new start time since ramp change
				ramp_st_temp = PID_setpoint;     //set new start temp since ramp change
				}
			last_button = true;
			}
		else if (buttonValue == ENTER) { //minus key was pushed, dec D if it was
			FanSpeed = FanSpeed - 2;
			}
		else if (buttonValue == ESC) { //minus key was pushed, inc D if it was
			FanSpeed = FanSpeed + 2;
			}
	    else {last_button = false;}
        buttonValue = 0;
		break;

	}  //switch case 

display_roast();   //display roast information on LCD

//idletime = float(millis()) / 1000.;
//idletime = 1.0 - (idletime - timestamp);
// arbitrary: complain if we don't have at least 10mS left
//if (idletime < 0.010) {
//Serial.print("# idle: ");
//Serial.println(idletime);
//}

}
