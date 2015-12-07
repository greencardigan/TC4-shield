// Kona.pde
// Kona project
#define VERSION 2.00

/*Other changes to make
user.h for release
profile for release
*/


// A PID roasting program for the Arduino using a TC4 thermocouple input.
// This program using Rate of Rise (ROR) to set up the roast profile

/*
Revision history
Version 2.00	Merged Moka and Kona into one program.

Arduino setup
The a_Kona.pde, PID.pde, U_defined.pde, U_roaster, button.pde, compensate.pde, display.pde, mode.pde, pick_profile.pde, serial.pde, tc4.pde and user.h must be in the same Arduino subdirectory.
When the skechbook is opened, tabs for each of these files should appear.

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
 
 thermocouple channel 2 is used as the Control Temp (CT), which controls the PID function
 In my roaster, CT is used for ET, and is located where the hot air first contacts the bean mass, at the bottom of the roasting chamber.
 thermocouple channel 1 is used as Monitor Temp (MT).  In my roaster, MT is Bean Temp, located where the hot air exits the bean mass.
 In Moka, the end of each step is when MT hits the target temp.

 Analog output 1 is (PWM) is used to control the heater SSR           (Arduino pin D9)
 Analog output 2 is (PWM) can be used to control the fan, optional    (Arduino pin D10)

 The program uses the roast profile described below.  There are 10 profiles supported.
 The profiles are stored in flash using PROGMEM, so there is a special step to read the infomation back.
 To change the profiles, you need to edit the profile information below, 
 and reload the program into the Arduino.

 LCD output is formatted for a 2x16 LCD.  
 See the display.pde file for the LCD routines.

 Support for Kona Roaster program
 Randy Tsuchiyama

*/

//  ------------------------  include files
#include <konalib.h>           //constants used by this program
#include "user.h"           //constants most likely to be changed by the user
#include <Wire.h>           //for I2C support
#include <TypeK.h>          //for using type K TC's
#include <LiquidCrystal.h>  //LCD library
#include <PWM16.h>          //Added for PWM
#include <avr/pgmspace.h>   // needed to store the profiles in flash
#include <cADC.h>           //for thermocouple interface support

// --------------------------------------------------------------------------------

// define sub routines here

void get_samples();
void logger();
void roast_mode_select();  //routine in mode.pde
void fly_changes();        //routine in mode.pde
void display_roast();      //routine in display.pde
void display_startup();    //routine in display.pde
void display_profile();    //routine in display.pde
void display_end();        //routine in display.pde
int wait_button();         //routine in button.pde
int get_button();          //routine in button.pde
void compensate ();        //routine in compensate.pde
void select_profile();     //routine in profile.pde
void serial_send_header();     //routine in serial.pde
void serial_send_data();     //routine in serial.pde

// ------------------------ conditional compiles or constants
// ------------------------ other compile directives
#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define NCHAN 2   // number of TC input channels
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output on serial port
#define D_MULT 0.001 // multiplier to convert temperatures from int to float
#define MT_FILTER 10 // filtering level (percent) for T1
#define CT_FILTER 10 // filtering level (percent) for T2
#define BAUD 57600  // serial baud rate

// fixme This value should be user selectable
#define NSAMPLES 10 // samples used for moving average calc for temperature

// use RISE_FILTER to adjust the sensitivity of the RoR calculation
// higher values will give a smoother RoR trace, but will also create more
// lag in the RoR value.  A good starting point is 70%, but for air poppers
// or other roasters where BT might be jumpy, then a higher value of RISE_FILTER
// will be needed.  Theoretical max. is 99%, but watch out for the lag when
// you get above 85%.
#define RISE_FILTER 70 // heavy filtering on non-displayed BT for RoR calculations

// ---------------------------- calibration of ADC and ambient temp sensor
#define CAL_GAIN 1.00 // substitute known gain adjustment from calibration
#define CAL_OFFSET 0 // subsitute known value for uV offset in ADC
#define AMB_OFFSET 0 // substitute known value for amb temp offset (Celsius)

// ambient sensor should be stable, so quick variations are probably noise
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings
#define ANALOG_IN // comment this line out if you do not connect a pot to anlg1 port


//****************************************************************************************************
//                  Global Variables
//****************************************************************************************************

//temperature related variables
float ramp_delta_temp; //delta temp for this ramp step
float delta_temp;      //delta temp, used to increment setpoint for each second
float target_temp;
float t_amb;		//ambient temp
float delta_t_per_sec;      // setpoint slope
float ROR;		// Rate of rise for manual roasting
float ct;         // Control temp, input from thermocouple ch 2
float ct_old;     // Control temp from previous cycle/second
float mt;         // Monitor temp, based on thermocouple ch 1
float RoRmt,RoRct; //Rate of Rise for mt and ct
float PID_setpoint;    // PID target temperature
float setpoint;       //setpoint is input to the compensate function, output of this function is PID_setpoint
float step_st_temp=0;      //saves the starting temp for current ramp step, reset to current time whenever ROR is changed

//time related variables
//int total_time;   // determine step
int step_timer;    // count down seconds till end of step
float start_roast = 0;  //time when roasts starts, use to offset global time to display roast time
float time_left;  //use to figure out how much time is left in the one second cycle, after everything is done.
float tod;
float step_st_time;       //saves the starting time for current ramp step, reset to current time whenever ROR is changed

//PID related variables
float Proportion = 0;   //variable to store Proportional term
float Integral = 0;     //variable to store Integral term
float Derivative = 0;   //variable to store Derivative term

int PID_error[11];      //array to save last 10 PID error values, used to calculate intergral term
int error_ptr = 0;

int PID_bias;
int PID_min;
int PID_offset;

int segment = 0;    // segment of the roast, some parameters will change depending on the segment we are in.
boolean SEG1_flag = false;  //flag to tell if segment 1 has started
boolean SEG2_flag = false;  //flag to tell if segment 2 has started

PWM16 pwmOut;
int output = 0;
uint32_t nextLoop;

int roast_mode;

int roast_method = 0;  //roast method used, time/temp auto, ror auto or ror manual
unsigned int PWM_T;  //pwm frequency is stored here  
boolean last_button = false;  //used as flag to accelerate rate of change after holding down button for 2 secs
boolean second_last_button = false;  //used as flag to accelerate rate of change after holding down button for 2 secs
boolean last_sel_button;
boolean second_last_sel_button;
boolean enable_comp = true;
int fan;
int FanSpeed;
boolean next_step;
float heat;
int step = 0;    // step of the roast
int buttonValue = 0;  // variable to store the analog input value coming from the switches

// arrays to store the profile information during the roast
char Profile_Name_buffer[NAME_SIZE];   
int ror_array[NMAX];   
int Temp_array[NMAX];   
int Time_array[NMAX]; 
int Offset_array[NMAX];   
int Speed_array[NMAX]; 
int max_temp;

boolean ror_change = false;

//arrays used for TC4 thermocouple data
int32_t temps[NCHAN]; //  stored temperatures are divided by D_MULT
int32_t ftemps[NCHAN]; // heavily filtered temps
int32_t ftimes[NCHAN]; // filtered sample timestamps
int32_t flast[NCHAN]; // for calculating derivative
int32_t lasttimes[NCHAN]; // for calculating derivative

int adc_delay;

// class objects used by thermocouple hardware/ADC
cADC adc( A_ADC ); // MCP3424
ambSensor amb( A_AMB ); // MCP9800
filterRC fT[NCHAN]; // filter for displayed/logged ET, BT
filterRC fRise[NCHAN]; // heavily filtered for calculating RoR


LiquidCrystal lcd( RS, ENABLE, DB4, DB5, DB6, DB7 );

int ledPin = 13;


//*****************************************************************************************************
// 
// Initialization Section, only runs once, at beginning of program
//
//******************************************************************************************************

void setup()
{
  byte a;
  int i;

pinMode(ledPin, OUTPUT);

#ifdef ALPENROST
pinMode (AR_MOTOR_ON_PIN, OUTPUT);   //output pin to turn on Alpenrost motor to turn drum
pinMode (AR_FLAP_CLOSE_PIN, OUTPUT);   //output pin to close the flap to start roast
pinMode (AR_FLAP_OPEN_PIN, OUTPUT);   //output pin to close the flap to start roast
pinMode (AR_MOTOR_REV_PIN, OUTPUT);   //output pin to turn on Alpenrost motor to turn drum
#endif

lcd.begin(COLS, ROWS);  //intialize LCD, COLS and ROWS are defined in user.h

Serial.begin(BAUD);

display_startup();  //in display.pde

delay (1500);

select_profile();  //in pick_profile.pde

roast_mode_select();  // in mode.pde
//note that if the user selects manual ror mode is "roast_mode_select_", then roast method is set the MANAUL_ROR

//Init the TC4 stuff
init_TC4();   //in tc4.pde

//Set PWM output frequency
pwm_init();  //in U_defined.pde

pwmOut.Setup( PWM_T );

//Setup initial PID parameters for bias and min output
PID_bias = SEG0_BIAS;
PID_min = SEG0_MIN;

FanSpeed = 80;  
heat = 60;
ct = 0;

#ifdef ALPENROST
start_alpen();  //in U_roaster.pde
#endif


while (ct < (STARTTEMP - 10) ) {    // wait until et is within 10 deg of this constant (make sure heater turns on), then continue
	get_samples();             //in tc4.pde
	//start heater and fan
	pwmOut.Out( heat, FanSpeed );
	display_roast();   //display roast information on LCD, routine in display.pde
	delay (500);
	}
	

//select roast method, based on ror array
if (ror_array[0] == 0) { //if 1st element in ror array is 0, then temp/time method roast
	roast_method = AUTO_TEMP; 	
	//setup parameters for step 0 
	ramp_delta_temp =   (Temp_array [0]) - STARTTEMP;
	delta_t_per_sec =  (ramp_delta_temp / (Time_array [0]));
	target_temp = Temp_array [0];
	step_timer = Time_array [step];
	FanSpeed = Speed_array [0];
	setpoint= STARTTEMP;
	}
else if (roast_mode == 3) { //if roast_mode == 3, then manual ror method was selected, set up for that
	roast_method = MANUAL_ROR;  
  	ROR = 50;                    // intialize ROR
	delta_t_per_sec = (ROR / 60);          //convert ROR from deg per min to slope in deg per second  
	setpoint= STARTTEMP;  //step_st_temp = STARTTEMP;	 //set init step start temp to the start of roast temp
	step_timer = 0;
    max_temp = MAXTEMP;
  }
else {   //else set up for auto ror roast method
	roast_method = AUTO_ROR; 	
	ROR = ror_array[0];                    // intialize ROR
	delta_t_per_sec = (ROR / 60);          //convert ROR from deg per min to slope in deg per second
	setpoint= STARTTEMP;  //step_st_temp = STARTTEMP;	 //set init step start temp to the start of roast temp
	step_timer = 0;
} 

if (Offset_array[6] != 0) {enable_comp = false;}  //turn off compensation if there is an offset value in the middle of the offset array

//setpoint = STARTTEMP;           // init setpoint to the start of roast temp
next_step = true;
//step = 0;

start_roast = millis() * 0.001;  //set start roast time to current time.  This is used to offset tod, so time displayed is for roast time

serial_send_header();

//next loop is used to decide to start the next cycle.
// note that a cycle is 1 second long.  Init nextloop to the current time + 0.1 second.
nextLoop = millis() + 100;  
   
} // end of setup


//*****************************************************************************************************
// 
// Main Program Loop
//
//******************************************************************************************************

void loop()
{
  // update on even 1 second boundaries
  while ( millis() < nextLoop ) { // wait until time to start next cycle, one second from last one
  }
  
  nextLoop += 1000; // time mark for start of next cycle, add 1 second to start time

buttonValue = 0;  //reset button pushed to not pushed
  
get_samples();  // retrieve values from MCP9800 and MCP3424
	
//logger();   //get ct and mt.

serial_send_data();  //send data to serial port, routine in serial.pde

/*
for( int j = 0; j < NCHAN; j++ ) {
	flast[j] = ftemps[j]; // use previous values for calculating RoR
	lasttimes[j] = ftimes[j];
	}
*/
// check to see if at the end of the roast profile
if (step > NMAX) {      //start cooling cycle, then stop sending data after 1 min.
	pwmOut.Out( 0,100 ); //shut off heater, set fan speed to full
	#ifdef ALPENROST  //if this is my alpenrost, open damper and reverse drum motor.
        end_alpen();
    #endif

	for (int i = 0; i<61; i++) {  //continue to send data to PC, but only for next 60 secs.
		get_samples();  // retrieve TC values from MCP9800 and MCP3424
		serial_send_data();  //send data to serial port, routine in serial.pde
		//for( int j = 0; j < NCHAN; j++ ) {
		//	flast[j] = ftemps[j]; // use previous values for calculating RoR
		//	lasttimes[j] = ftimes[j];
		//	}
		display_ending();  //display used while roast is ending (cooling cycle)
		while ( millis() < nextLoop ) { }// wait until the start of the next second
		nextLoop += 1000; // time mark for start of next cycle, add 1 second to start time
		}
	display_end();       //display end of roast message
	serial_send_end();   //send end of roast message on serial port
	while (1>0) {}       //wait forever, until power down reset
	}

	
switch (roast_method){
	case (AUTO_TEMP):
	if (step_timer <= 0) {
		setpoint = Temp_array [step];  //reset setpoint to target temp for step just completed, in case of small math errors
		step = step + 1;               //go to next step
//		step_st_time = millis() * 0.001; //set new start time for next step
//total_time = step_st_time + (Time_array [step]);  //setup serial time as the end time for this step;
		//added following in case temp was changed manually, to make sure temp for next step is not lower then current target temp
		if (target_temp > (Temp_array [step])) 
			{Temp_array [step] = target_temp;}
		else
			{target_temp = Temp_array [step]; }
		ramp_delta_temp =  ( (target_temp) - (Temp_array [(step - 1)]) );
		delta_t_per_sec =  (ramp_delta_temp / (Time_array [step]));  //calculate delta temp per second
		step_timer = Time_array [step];     //set step timer to time for this step.  In this method, step time is decremented.
		FanSpeed = Speed_array [step];
		}
	step_timer--;   //decrement time left in step
//setpoint is the target temp of the last step + delta_t_per_sec 
	setpoint = setpoint + delta_t_per_sec;  //add delta temp per sec to previous setpoint
	
	break;
		   
	case (AUTO_ROR):
   //automatic ROR roast per profile
	if (Time_array[step] == 0) {    //if time for this step = 0, then perform a ROR type step
		if (mt >= Temp_array[step]) {  //when measured temp reaches target temp, go to next step
			step++;
//			step_st_time = millis() * 0.001; //set new start time for next step
//			step_st_temp = setpoint;     //set new start temp for next step
			ROR = ror_array[step];           //get ROR for next step   
			delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to delta temp per second
			step_timer = 0;                     //reset step timer
			}
		// determine PID setpoint based on delta_t_per_sec (ramp) and time
		step_timer ++; //see how long it has been in this step, use step timer in incrementing mode
		setpoint = setpoint + delta_t_per_sec;  //current target temp is setpoint plus slope
		if (setpoint > max_temp) { //do not allow setpoint to exceed max temp 
			setpoint = max_temp; } //note that MAXTEMP is defined in profile.pde as "profile_maxtempXX", per profile
		}
	else {     //else time > 0, do a timed step, without changing setpoint, use step timer in decrementing mode
		if (step_timer < 0) {
			step++;
			step_timer = Time_array[step];
			}
		else {
			step_timer--;
			}
		}
		break;

	case (MANUAL_ROR):
		step_timer++; //for manual ROR roasting, using step_timer for how long at this ramp rate, step_timer in inc mode
		//delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
		setpoint = setpoint + delta_t_per_sec;  //current target temp is setpoint plus slope
		if (setpoint > max_temp) { //do not allow setpoint to exceed max temp constant
			setpoint = max_temp; } //note that MAXTEMP is defined in user.h
        break;
	}		

// PID control, adjust heater output 
PID();
heat = output;

if (FanSpeed > 100) {FanSpeed = 100;}  //Make sure FanSpeed is within limits
else if (FanSpeed < 40) {FanSpeed = 40;}

//write new PID value to pwm pins
pwmOut.Out( heat, FanSpeed );

//remember old ct for next cycle
ct_old = ct;

fly_changes ();  // in mode.pde

display_roast();   //display roast information on LCD  routine in display.pde

time_left = nextLoop - millis() ;


}
