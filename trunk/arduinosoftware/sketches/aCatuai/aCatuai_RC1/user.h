// *************************************************************************************
// NOTE TO USERS: the following parameters should be
// be reviewed to suit your preferences and hardware setup.  
// First, load and edit this sketch in the Arduino IDE.
// Next compile the sketch and upload it to the Duemilanove.

// ------------------ optionally, use I2C port expander for LCD interface
//#define I2C_LCD //comment out to use the standard parallel LCD 4-bit interface
#define LCD_20_4 //comment out to use 16x2 LCD
#define c23008  //Comment out if not using JeeLabs expander
#define FANCONTROL  //Comment out if not using Fan control on DIO11
// ------ connect a potentiomenter to ANLG1 for manual heater control using Ot1
//#define ANALOG_IN // comment this line out if you do not use this feature

//
#ifdef c23008
#define Key_Count_Size 4
#define LOADPOWER 45    //Heat power at load beans
#define STARTSPEED  70  //Fan speed on startup
#define LOADSPEED 90   //Speed at load beans
#define ENDSPEED 95    //Speed at end of roast
#define FANPIN 11    //DIO pin for DC fan speed via TIP120
#define EVENT_DELAY  2   //Ensure events not updated too quickly
#define ResetTime 5000  //Reset after 5 seconds of enter key
#endif

#ifdef FANCONTROL
#define STARTSPEED  70  //Fan speed on startup
#define LOADSPEED 90   //Speed at load beans
#define FANPIN 11    //DIO pin for DC fan speed via TIP120
#endif