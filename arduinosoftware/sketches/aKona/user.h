#ifndef USER_H
#define USER_H

float Pb = 70;     //Proportional Constant  
float I = 10;        //Integral Constant
float D = 25;        //Derivative Constant

int PID_factor = 3;   // scale down the PID output by this factor (divide by it) 

#define STARTTEMP 140  // program starts profile when control temp reaches this number

#define MAXTEMP 542  // max temp to set temp limit for manual ROR roasts 

// define the segment boundaries
#define SEGMENT_1 2 // Segment 1 starts when the roast step is 2
#define SEGMENT_2 4 // Segment 2 starts when the roast step is 4

// define the segment based parameters
//PID output will be centered around the bias value, all corrections will be to this value.
#define SEG0_BIAS 40   //Bias value for the early parts of the roast
#define SEG1_BIAS 45   //Bias value for the middle parts of the roast
#define SEG2_BIAS 45   //Bias value for the later parts of the roast
//min PID output value.
#define SEG0_MIN 20   //minimum value for the early parts of the roast
#define SEG1_MIN 25   //minimum value for the middle parts of the roast
#define SEG2_MIN 30   //minimum value for the later parts of the roast


#define RS 2
#define ENABLE 4
#define DB4 7
#define DB5 8
#define DB6 12
#define DB7 13

#define LCD4X20 true
#define ALPENROST true
#define EEROM true

#ifdef LCD4X20
#define ROWS 4  //use this for a 4 row display
#define COLS 20  //use this for a 20 column display
#else
#define ROWS 2  //use this for a 2 row display
#define COLS 16  // use this for a 16 column display
#endif  //if 4X20

#endif
