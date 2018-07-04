#ifndef konalib003_H
#define konalib003_H
#include "WProgram.h" //I'm not sure why, but I couldn't use boolean variables in this file unless I have this

//set to true to enable temp compensation algorithm in compensate.pde, false to disable is default
boolean enable_comp = true;

#define MAX_PROFILE 20 // max number of profiles

//compiler options, depending on roaster configuration
#define LCD4X20  //remove comment on this line if using 4x20 LCD
#define ALPENROST
//#define EEROM
//#define PORTEXPANDER

#ifdef LCD4X20
#define ROWS 4  //use this for a 4 row display
#define COLS 20  //use this for a 20 column display
#else
#define ROWS 2  //use this for a 2 row display
#define COLS 16  // use this for a 16 column display
#endif  //if 4X20

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

#define AUTO_TEMP   1   //roast method automatic using profile, temperature/time method
#define AUTO_ROR    2   //roast method automatic using profile, ror method
#define MANUAL_ROR  3   //roast method manual user controlled, ror method

#define NO_SEGMENTS 2 // currently support 3 roast segments

#define PROFILE_ADDR_PID 200 // address in EEprom to store the PID setup data
#define PROFILE_ADDR_01 5000 // address in EEprom to store the profile data
#define PROFILE_ADDR_RX 5000 // address in EEprom to store the profile data, for data sent from PC

//structure for temp storage of the profiles
struct profile {
  int index;      //0-1
  char name[16];  //2-17 
  char date[16];  //format yyyy/mm/dd hh:mm
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
  int profile_method;

};

profile myprofile;  //structure used to store profile data


//structure for storage of PID info in EEprom
struct PID_struc {
  int init_pattern;
  float Pb;
  float I;  
  float D; 
  float PID_factor;
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
  int startheat;
  };

PID_struc myPID;  //structure used to read/write the PID data


//#ifdef ALPENROST
//---------------------------Port Expander Alpenrost control bits
// bit 3 = flap close, bit 2 = flap open, bit 1 = motor on
#define ALP_MOTOR_ON            (uint8_t) B00000001
#define ALP_FLAP_OPEN           (uint8_t) B00000010
#define ALP_FLAP_OPEN_MOTOR_ON  (uint8_t) B00000011
#define ALP_FLAP_CLOSE          (uint8_t) B00000100
#define ALP_FLAP_CLOSE_MOTOR_ON (uint8_t) B00000101
#define ALL_ON                  (uint8_t) B11111111
//#endif





#endif