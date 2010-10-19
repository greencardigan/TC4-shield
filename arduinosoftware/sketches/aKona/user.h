#ifndef USER_H
#define USER_H
#include "WProgram.h" //I'm not sure why, but I couldn't use boolean variables in this file unless I have this

float Pb = 70;     //Proportional Constant  
float I = 10;        //Integral Constant
float D = 25;        //Derivative Constant

//default
int PID_factor = 1;   // scale down the PID output by this factor (divide by it) 


#define STARTTEMP 150  // program starts profile when control temp reaches this number

#define MAXTEMP 525  // max temp to set temp limit for manual ROR roasts 

//default
//set to true to enable temp compensation algorithm in compensate.pde, false to disable is default
boolean enable_comp = false;

// define the segment boundaries
#define SEGMENT_1 2 // Segment 1 starts when the roast step is 2
#define SEGMENT_2 4 // Segment 2 starts when the roast step is 4

// define the segment based parameters
//PID output will be centered around the bias value, all corrections will be to this value.
#define SEG0_BIAS 0   //Bias value for the early parts of the roast
#define SEG1_BIAS 0   //Bias value for the middle parts of the roast
#define SEG2_BIAS 0   //Bias value for the later parts of the roast
//min PID output value.
#define SEG0_MIN 0   //minimum value for the early parts of the roast
#define SEG1_MIN 0   //minimum value for the middle parts of the roast
#define SEG2_MIN 0   //minimum value for the later parts of the roast


#define RS 2
#define ENABLE 4
#define DB4 7
#define DB5 8
#define DB6 12
#define DB7 13

//compiler options, depending on roaster configuration
//#define LCD4X20  //remove comment on this line if using 4x20 LCD
//#define ALPENROST
//#define EEROM
//#define PORTEXPANDER

#ifdef LCD4X20
#define ROWS 4  //use this for a 4 row display
#define COLS 20  //use this for a 20 column display
#else
#define ROWS 2  //use this for a 2 row display
#define COLS 16  // use this for a 16 column display
#endif  //if 4X20

#endif
