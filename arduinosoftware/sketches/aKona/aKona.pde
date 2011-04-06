 // Kona.pde
// Kona project
#define VERSION 5.01

/*
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

// A PID roasting program for the Arduino using a TC4 thermocouple input.

Revision history
Version 4.00	Implemented I2C EEprom, so profiles and PID constants are stored in EEprom.  Can receive profiles from processing program.
Version 3.00    Moved buttons to I2C port expander
Version 2.00	Merged Moka and Kona into one program.

Arduino setup
The a_Kona.pde, PID.pde, U_defined.pde, U_roaster, button.pde, compensate.pde, display.pde, mode.pde, pick_profile.pde, serial.pde, tc4.pde and user.h 
and others must be in the same Arduino subdirectory.
When the skechbook is opened, tabs for each of these files should appear.

 Written by Randy Tsuchiyama
 This is intended to provide PID type control to roast coffee using an Arduino.
 The author has a hot air (popcorn popper) based roaster and a modified Alpenrost, but it should work for other roasters
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

 Support for Kona Roaster program
 Randy Tsuchiyama
*/

//  ------------------------  include files
#include <konalib002.h>           //constants used by this program
#include "user.h"           //constants most likely to be changed by the user
#include <Wire.h>           //for I2C support
#include <avr/pgmspace.h>   // needed to store the profiles in flash, so they can be written into eeprom
#include <TypeK.h>          //for using type K TC's written by Jim Galt
#include <PWM16.h>          //Added for PWM, written by Jim Galt
#include <cADC.h>           //for thermocouple interface support written by Jim Galt
#include <mcEEPROM.h>       //for accessing eeprom
#include <cLCD.h>            // for lcd through port expander
#include <cButton.h>        //for reading buttons through port expander

//#include <LiquidCrystal.h>  //LCD library

//class variables used for libraries
PWM16 pwmOut;
cButtonPE16 buttons;
cLCD lcd;
mcEEPROM ep;

// --------------------------------------------------------------------------------

// define sub routines here

void get_samples();
void init_temp1();
void roast_mode_select();  //routine in mode.pde
void fly_changes();        //routine in mode.pde
void display_roast();      //routine in display.pde
void display_startup();    //routine in display.pde
void display_select_action(int); 
void display_profile();    //routine in display.pde
void display_start_roast(); //routine is display.pde
void display_end();        //routine in display.pde
void display_ending();      //routine in display.pde
int wait_button();         //routine in button.pde
int get_button();          //routine in button.pde
//void compensate (float);        //routine in compensate.pde
boolean select_profile();     //routine in profile.pde
void serial_send_header();     //routine in serial.pde
void serial_send_data();     //routine in serial.pde
void serial_send_end();      //routine in serial.pde
void init_TC4 ();          //routine in tc4.pde
void pwm_init();           //in U_defined.pde
void init_PID();            //routine in PID.pde
void PID();            //routine in PID.pde
void profile_act();        //routine in profile.pde

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
//#define ANALOG_IN // comment this line out if you do not connect a pot to anlg1 port


//****************************************************************************************************
//                  Global Variables
//****************************************************************************************************

//temperature related variables
float ramp_delta_temp; //delta temp for the current ramp step
float delta_temp;      //delta temp, used to increment setpoint for each second
float target_temp;
float t_amb;		//ambient temp
float delta_t_per_sec;      // setpoint slope
float ROR;		// Rate of rise
float ct;         // Control temp, input from thermocouple ch 2
float ct_old;     // Control temp from previous cycle/second
float mt;         // Monitor temp, based on thermocouple ch 1
float mt_old;     // Monitor temp from previous cycle/second
float RoRmt,RoRct; //Rate of Rise for mt and ct
float PID_setpoint;    // PID target temperature
float setpoint;       //setpoint is input to the compensate function, output of this function is PID_setpoint
float step_st_temp=0;      //saves the starting temp for current ramp step, reset to current time whenever ROR is changed

//time related variables
int step_timer;    // count down seconds till end of step
float start_roast = 0;  //time when roasts starts, use to offset global time to display roast time
float time_left;  //use to figure out how much time is left in the one second cycle, after everything is done.
float tod;
float step_st_time;       //saves the starting time for current ramp step, reset to current time if ROR is manually changed

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
int prof_cntr = 0;  //set in pick profile.pde, select_profile() function, to set which profile number was selected.  it is used by the program that called it

int inc=0;  //amount to inc a value during edit
float inc_flt=0;  //amount to inc a value during edit

int output = 0;
uint32_t nextLoop;

//Flags
boolean last_button = false;  //used as flag to accelerate rate of change after holding down button for 2 secs
boolean second_last_button = false;  //used as flag to accelerate rate of change after holding down button for 2 secs
boolean last_sel_button;
boolean second_last_sel_button;
//boolean enable_comp = true;
boolean next_step;
boolean ror_change = false;
boolean SEG1_flag = false;  //flag to tell if segment 1 has started
boolean SEG2_flag = false;  //flag to tell if segment 2 has started


int roast_method = 0;  //roast method used, time/temp auto, ror auto or ror manual
unsigned int PWM_T;  //pwm frequency is stored here  
int roast_mode;
//int fan;
int FanSpeed;

float heat;
int step = 0;    // step of the roast
int buttonValue = 0;  // variable to store the analog input value coming from the switches

int max_temp;

char char_buf[20];  //buffer for display strings and serial output strings

int *edit_ptr;      //points to variable to edit, if variable is int
float *edit_flt_ptr;  //points to variable to edit, if variable is float
char *char_ptr;     //pointer for strings or char arrays
byte *byte_ptr;     //pointer for bytes

int serial_in_cnt = 0;  //counter for serial input data
byte serial_in_line[10];  //input line array, 
char in_Char;
int in_val = 0;
int in_digit = 0;
boolean serial_command_rx;
int serial_command;
boolean remote_mode = false;
int temp_int;

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

//function pointers
void (*dsp_function)(int) = NULL;   //create func ptr.  Points to a display routine, to tell program which display to use


//LiquidCrystal lcd( RS, ENABLE, DB4, DB5, DB6, DB7 );  //used if LCD is connected to the Aruduino pins

//int ledPin = 13;   //used if LCD is connected to the Aruduino pins


//*****************************************************************************************************
// 
// Initialization Section, only runs once, at beginning of program
//
//******************************************************************************************************

void setup()
{
  byte a;
  int i;
  int act = 0;
  boolean pick = false;
  float temp_float = 0;
  
Wire.begin(); //start I2C bus

buttons.begin(4);  //initialize button reader

pinMode (ALP_MOTOR_ON, OUTPUT);
pinMode (ALP_FLAP_OPEN, OUTPUT);
pinMode (ALP_FLAP_CLOSE, OUTPUT);

lcd.begin(COLS, ROWS);  //intialize LCD, COLS and ROWS are defined in user.h

Serial.begin(BAUD);    //start serial port

//display startup screen
display_startup();  //in display.pde

delay (500);

buttonValue = 0;

init_PID();  //read PID parameters from eeprom, function in aPID

//init variables used by the following while loop, which controls the upper level menu selection
act = 0;
boolean done_00 = false;
boolean done_pick = false;
boolean pick_00 = false;
int temp_int = 0;
int *pnt;

dsp_function = &display_select_action; //function pointer, point to function to display screen for this selection
dsp_function (act);  //write display for the first time

while (done_pick==false) {
  pnt = &act;      //set pointer for this section
  dsp_function = &display_select_action; //init again, if profile_act or configure_act are called, need to put back
  pick_00 = ( select_something_nowait (2, pnt) ) ;  //call select something function in util.pde
  if (pick_00 == true) { 
//note  act ==0 for roasting, do nothing and continue
    if (act == 0) {
      pick_00 = true;
      done_pick = true;
      }
    else if (act == 1) {
      show_profile();
      //profile_act();  //in profile_act.pde
      }
    else if (act == 2) {  //configuration
      configure_act();
      }
    } //end if pick_00
  
  serial_read ();
  if (serial_command_rx == true) {
     if ((serial_in_line[0] == 'r') || (serial_in_line[0] == 'R')) {  //see if a roast command was sent
         byte_ptr = &serial_in_line[1];              //set pointer to first number in the serial input string
         temp_int = (convert_int());    //  convert_int is a function that converts a string to an int
         if (temp_int < MAX_PROFILE) {
            read_rec_profile(temp_int);    //read in profile from eeprom into ram.  
            max_temp = myprofile.maxtemp;
            done_pick = true;
            remote_mode = true;
            display_profile(temp_int);
            delay (2000);
            }
         }
     else if ((serial_in_line[0] == 'a') || (serial_in_line[0] == 'A')) {  //see if a receive profile command was sent
         receive_profile();                 //go receive profile
         }
     else if ((serial_in_line[0] == 'b') || (serial_in_line[0] == 'B')) {  //see if a send eeprom/PID parameters command was sent
         send_PID();                 //go send the PID params to the serial IF
         }
     else if ((serial_in_line[0] == 'i') || (serial_in_line[0] == 'I')) {  //see if a init eeprom command was sent
         init_eeprom();                 //go initialize eeprom with stored PID parameters
         }
     else if ((serial_in_line[0] == 'p') || (serial_in_line[0] == 'P')) {  //see if a store eeprom command was sent
         byte_ptr = &serial_in_line[1];              //set point to first number in the serial input string
         temp_int = convert_int();    //read in profile from eeprom into ram.  convert_int is a function that converts a string to an int
         temp_float = convert_float ();    //convert_float is a function that converts a string to a float
         update_eeprom(temp_int,temp_float);  //go write new value into eeprom
         }
     serial_command_rx = false;
     }
  } //end while
  
  
//display_start_roast();

if (remote_mode == false) {	
   //now go select profile to run
   select_profile();  //in pick_profile.pde

   roast_mode_select();  // in mode.pde
   //note that if the user selects manual ror mode is "roast_mode_select_", then roast method is set the MANAUL_ROR
   }
   
//Init the TC4 stuff
init_TC4();   //in tc4.pde

//Set PWM output frequency
pwm_init();  //in U_defined.pde

pwmOut.Setup( PWM_T );

//Setup initial PID parameters for bias and min output
PID_bias = myPID.seg0_bias;
PID_min = myPID.seg0_min;

FanSpeed = 80;  
heat = myPID.startheat;
//init_temp1;
get_samples;

digitalWrite(ALP_MOTOR_ON, 1);
digitalWrite(ALP_FLAP_OPEN, 0);
digitalWrite(ALP_FLAP_CLOSE, 1);
 
//if (myPID.roaster == ALPENROST) {
//   start_alpen();  //in U_roaster.pde
//   }

while (ct < (myPID.starttemp) ) {    // wait until et is at start temp (make sure heater turns on), then continue
	get_samples();             //in tc4.pde 
        //init_temp1;
	//start heater and fan
	pwmOut.Out( heat, FanSpeed );
	setpoint= myPID.starttemp;  //set init step start temp to the start of roast temp
	display_roast();   //display roast information on LCD, routine in display.pde
	delay (500);
        ct_old = ct;
        mt_old = mt;
	}
	

//select roast method, based on profile_method variable in profile array
if ((myprofile.profile_method == 1) || (myprofile.profile_method == 4))  {   // 1=time,temp;  2=auto ror, 3=manual ror, 4=artisan, 5=deltaT
	roast_method = AUTO_TEMP; 	
	//setup parameters for step 0 
	ramp_delta_temp =   (myprofile.targ_temp [0]) - myPID.starttemp;
	delta_t_per_sec =  (ramp_delta_temp / (myprofile.time [0]));
	target_temp = myprofile.targ_temp [0];
	step_timer = myprofile.time [step];
	FanSpeed = myprofile.speed [0];
	setpoint= myPID.starttemp;
        max_temp = myprofile.maxtemp;
      	}
else if (myprofile.profile_method == 2)  {   // 2=auto ror, set up for auto ror roast method
	roast_method = AUTO_ROR; 	
	ROR = myprofile.ror[0];                    // intialize ROR
	delta_t_per_sec = (ROR / 60);          //convert ROR from deg per min to slope in deg per second
	setpoint= myPID.starttemp;  //set init step start temp to the start of roast temp
	step_timer = 0;
        max_temp = myprofile.maxtemp;
        } 
else if (roast_mode == 3) { //if roast_mode == 3, then manual ror method was selected, set up for that
	roast_method = MANUAL_ROR;  
  	ROR = 50;                    // intialize ROR
	delta_t_per_sec = (ROR / 60);          //convert ROR from deg per min to slope in deg per second  
	setpoint= myPID.starttemp;  //step_st_temp = STARTTEMP;	 //set init step start temp to the start of roast temp
	step_timer = 0;
        max_temp = myPID.maxtemp;
  }

if (myprofile.offset[6] != 0) {enable_comp = false;}  //turn off compensation if there is an offset value in the middle of the offset array
else {enable_comp = true;}

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
	
//make sure ct and mt did not change too much, which means they are a garbage reading
//if they are garbage, use the old reading instead
if (ct > myPID.starttemp) {
  if (ct > (ct_old + 20)) {
    ct = ct_old;
    temps[1] = ct/D_MULT;
    }
  else if (ct < (ct_old - 20)) {
    ct = ct_old;
    temps[1] = ct/D_MULT;
    }
  }
if (mt > myPID.starttemp) {
  if (mt > (mt_old + 20)) {
    mt = mt_old;
    temps[0] = mt/D_MULT;
    }
  else if (mt < (mt_old - 20)) {
    mt = mt_old;
    temps[0] = mt/D_MULT;
    }
  }

// check to see if at the end of the roast profile
if (step > NMAX) {      //start cooling cycle, then stop sending data after 1 min.
   pwmOut.Out( 0,100 ); //shut off heater, set fan speed to full
   //if (myPID.roaster == ALPENROST) {
       digitalWrite(ALP_FLAP_OPEN, 1);
       digitalWrite(ALP_FLAP_CLOSE, 0);

     	//#ifdef ALPENROST  //if this is my alpenrost, open damper and reverse drum motor.
//        end_alpen(); }     //routine in U_roaster.pde
//    #endif

	for (int i = 0; i<61; i++) {  //continue to send data to PC, but only for next 60 secs.
		get_samples();  // retrieve TC values from MCP9800 and MCP3424
		serial_send_data();  //send data to serial port, routine in serial.pde
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
		setpoint = myprofile.targ_temp[step];  //reset setpoint to target temp for step just completed, in case of small math errors
		step = step + 1;               //go to next step
//		step_st_time = millis() * 0.001; //set new start time for next step
//total_time = step_st_time + (myprofile_r.time [step]);  //setup serial time as the end time for this step;
		//added following in case temp was changed manually, to make sure temp for next step is not lower then current target temp
		if (target_temp > (myprofile.targ_temp[step])) 
			{myprofile.targ_temp [step] = target_temp;}
		else
			{target_temp = myprofile.targ_temp[step]; }
		ramp_delta_temp =  ( (target_temp) - (myprofile.targ_temp [(step - 1)]) );
		delta_t_per_sec =  (ramp_delta_temp / (myprofile.time [step]));  //calculate delta temp per second
		step_timer = myprofile.time [step];     //set step timer to time for this step.  In this method, step time is decremented.
		FanSpeed = myprofile.speed [step];
		}
	step_timer--;   //decrement time left in step
//setpoint is the target temp of the last step + delta_t_per_sec 
	setpoint = setpoint + delta_t_per_sec;  //add delta temp per sec to previous setpoint
	
	break;
		   
	case (AUTO_ROR):
  if (myprofile.time[step] == 0) {    //if time for this step = 0, then perform a ROR type step
    if (mt >= target_temp) {  //when measured temp reaches target temp, then time to go to next step
      step++;  //increment step counter
      if (myprofile.time[step] == 0) {    //if time for next step = 0, then setup for a ROR type step
        ROR = myprofile.ror[step];           //get ROR for this step   
        delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to delta temp per second
        step_timer = 0;                     //reset step timer
        target_temp = myprofile.targ_temp [step];  //set new target temp, for this step
        }
      else {  //setup for a timed step
        step_timer = myprofile.time[step];
        }
      }	
    else {	//else have have reached target temp yet, update setpoint for next second
      step_timer ++; //see how long it has been in this step, use step timer in incrementing mode
      setpoint = setpoint + delta_t_per_sec;  //current target temp is setpoint plus slope
      if (setpoint > max_temp) { //do not allow setpoint to exceed max temp 
        setpoint = max_temp;  //note that MAXTEMP is defined per profile, in the profile structure
        }
      }
    }
    // determine PID setpoint based on delta_t_per_sec (ramp) and time
  else {     //else time > 0, do a timed step, without changing setpoint, use step timer in decrementing mode
    if (step_timer <= 0) {  //if step timer reaches 0, then go to next step
      step++;
    if (myprofile.time[step] == 0) {    //if time for next step = 0, then setup for a ROR type step
      ROR = myprofile.ror[step];           //get ROR for this step   
      delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to delta temp per second
      step_timer = 0;                     //reset step timer
      target_temp = myprofile.targ_temp [step];  //set new target temp, for this step
      }
    else {  //setup for a timed step
      step_timer = myprofile.time[step];
      }
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

fly_changes ();  // in mode.pde

//remember old ct for next cycle
ct_old = ct;
mt_old = mt;

display_roast();   //display roast information on LCD  routine in display.pde

if (myPID.serial_type == pkona) {
   serial_send_data();  //send data to serial port, routine in serial.pde
   }
//else if (myPID.serial_type == artisan) {
   serial_read_art();
//   }

time_left = nextLoop - millis() ;


}
