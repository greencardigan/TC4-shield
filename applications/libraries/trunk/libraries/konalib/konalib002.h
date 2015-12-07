#ifndef konalib002_H
#define konalib002_H
#include "WProgram.h" //I'm not sure why, but I couldn't use boolean variables in this file unless I have this

//set to true to enable temp compensation algorithm in compensate.pde, false to disable is default
boolean enable_comp = true;

///////////
//button wiring
//On Jim’s board, looking at the display, the rightmost button is bit zero and the leftmost is bit 3
//Esc wired to port 0, Select wired to port 1, Plus wired port 2, minus wired to port 3
//
// -------------------------- Settings and Values for Button switches and button wiring
//new settings, for Jim's board, these lines are for reference only
//#define ESCAPE_BUTTON      0      // read Escape switch on analog input port 3
//#define SELECT_BUTTON      1      // read Select switch on analog input port 0
//#define PLUS_BUTTON        2      // read ESC and PLUS switches on analog input port 2
//#define MINUS_BUTTON       3      // read MINUS switch on analog input port 1

//note, the values defined below need to correspond to the port where the switch is connected to, on the port expander
// for example, the Escape switch is connected to port 0, Select on port 1, etc
#define ESCAPE     0       // set to this value if ESCAPE is pushed, also port expander port
#define SELECT     1       // set to this value if SELECT is pushed
#define UP_PLUS    2       // set to this value if Plus is pushed 
#define DOWN_MINUS 3       // set to this value if Minus is pushed 
#define FIFTH     4       // fifth button is not used
#define NOBUTTON   5       // set to this value if no button was pushed 

// --------------------------RTC settings
#define DS1307_ADDR 0x68  // RTC I2C address

// --------------------------Profile settings
#define NMAX 14 //  max. number of steps in the profile.  Increase this number to add
//                  more steps
#define NAME_SIZE 16 //size of the profile name varibles
#define NO_PROFILES 10  //max number of profiles

//definitions for roast_mode
#define AUTO_TEMP   1   //roast method automatic using profile, temperature/time method
#define AUTO_ROR    2   //roast method automatic using profile, ror method
#define MANUAL_ROR  3   //roast method manual user controlled, ror method
#define DELTA_T     4   //roast method automatic using profile, delta temp method

//definitions for serial_type
#define PKONA       1   //if running pkona on PC
#define ARTISAN     2   //if running artisan on pc

//definitions for roaster
#define DEFAULT_ROASTER 1  //if using an air popper
#define ALPENROST       2   //if using an alpenrost
#define AIR_POPPER      3   //if using an air popper

#define NO_SEGMENTS 2 // currently support 3 roast segments

#define PROFILE_ADDR_PID 200 // address in EEprom to store the PID setup data
#define PROFILE_ADDR_01 5000 // address in EEprom to store the profile data
#define PROFILE_ADDR_RX 5000 // address in EEprom to store the profile data, for data sent from PC

#define NAME_LENGTH 20 // 
#define DATE_LENGTH 16 // 

//structure used for eeprom storage of the profiles
struct profile {
  char name[NAME_LENGTH];  // 
  char date[DATE_LENGTH];  //format yyyy/mm/dd hh:mm
  int index;      //0-100
  int ror[NMAX];
  int targ_temp[NMAX];
  int time[NMAX];
  int offset[NMAX];
  int speed[NMAX];
  int delta_temp[NMAX];
  int tbd01[NMAX];
  int tbd02[NMAX];
  int tbd03[NMAX];	
  int maxtemp;
  int profile_method;   // 1=time,temp;  2=auto ror, 3=manual ror, 4=deltaT, 5=tbd

};

profile myprofile;  //structure used to read in a profile from eeprom

//structure for storage of PID info in EEprom
struct PID_struc {
  int init_pattern;
  float Pb;
  float I;  
  float D; 
  float PID_factor;
  int starttemp;
  int maxtemp;
  int segment_0;
  int segment_1;
  int segment_2;
  int seg0_bias;
  int seg1_bias;
  int seg2_bias;
  int seg0_min;
  int seg1_min;
  int seg2_min;
  int startheat;
  int serial_type;
  int roaster;
  };

PID_struc myPID;  //structure used to read/write the PID data

#define ALP_MOTOR_ON     2
#define ALP_FLAP_OPEN    5  
#define ALP_FLAP_CLOSE   6 


/*
For information, the Arduino Discrete IO pin assignments
Serial RX			 0
Serial TX			 1
ALP motor on	 2
  	           3
				       4
Alp flap open  5  
Alp flap close 6  
				       7
		           8
Heater PWM Out 9
Fan PWM Out		10
 	            11 
				      12
				      13

A0		
A1		
A2		
A3		
A4		I2C
A5		I2C

*/



#endif
