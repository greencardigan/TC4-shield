//Randy's User.h file

#ifndef USER_H
#define USER_H
#include "WProgram.h" //I'm not sure why, but I couldn't use boolean variables in this file unless I have this

#define MAX_PROFILE 30 // max number of profiles

#define RS 2
#define ENABLE 4
#define DB4 7
#define DB5 8
#define DB6 12
#define DB7 13

//compiler options, depending on roaster configuration
#define LCD4X20  //remove comment on this line if using 4x20 LCD
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
