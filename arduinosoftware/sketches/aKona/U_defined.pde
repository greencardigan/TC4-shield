/*
User_defined.pde
This one of the files where user defined infomation goes.  user.h is the other one

The roasting profiles are defined here, and tthe PWM frequency is setup here.
*/

#include <PWM16.h>          //Added for PWM
void pwm_init()
{
// -------------------------- setup PWM Frequency

//Speeds that would work include pwmN128Hz, pwmN60Hz, pwmN50Hz, pwmN32Hz, pwmN30Hz, pwmN16Hz, pwmN8Hz, pwmN4Hz, pwmN2Hz, pwmN1Hz, pwmN2sec,pwmN4sec
//PWM_T = pwmN16Hz;  //set the PWM frequency to 16 Hz

PWM_T = pwmN30Hz;  //set the PWM frequency to 30 Hz
//PWM_T = pwmN60Hz;  //set the PWM frequency to 60 Hz
}


/*
Roasting profile information
There are two types of profiles, time/temp and ror

A profile will use the time/temp algorithm is the first element of the ror line is 0, as shown below
PROGMEM  prog_uint16_t profile_ror_09[] =   {  0, 150, 150, 280, 280, 380, 455, 540, 550, 550, 550, 580, 580, 580};  //ROR

If the first element of the ror line is none zero (71 in the example below)
then the auto ror algorithm will be selected
PROGMEM  prog_uint16_t profile_ror_00[] =  {  71,  70,  30,  20,  10,   5,  10,   0,   0,   0,   0,   0,   0,   0};  //ror 
*/

//Speeds that would work include pwmN16Hz, pwmN8Hz, pwmN4Hz, pwmN2Hz, pwmN1Hz, pwmN2sec,pwmN4sec
//it does suppport faster speeds, but I don't think it would make sense to try to switch faster then 16 hz

//********************************************************************************************************
//***************  SETUP Profiles here   *****************************************************************
//********************************************************************************************************

// row 1 (prog_uint16_t profile_ror_00) contains the Rate of Rise (ror) data, in degs F per min.  The program will attempt to keep this ror for the control temp (ct)
// row 2 (prog_uint16_t profile_temp_00) contains the temp target for each step.  The step ends when this temp is reached, for monitor temp (mt).
// row 3 (prog_uint16_t profile_time_00) if the time = 0, then time is not used, ror control is used
//                                       if time > 0, then ct will be held constant for this step, for the time in seconds.  This allows a soak period at constant temp
// row 4 (prog_uint16_t profile_offset_00) contains the temp offset, per step
// row 5 (prog_uint16_t profile_fan_00) contains the fan speed setting


//*********** Profile 00 Definition
prog_uchar profile_name_00[] PROGMEM  = {"R Mex Decaf 01  "};  //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_00[] =  {  70,  50,  20,  10,   5,   5,   5,   0,   0,   0,   0,   0,   0,   0};  //ror 
PROGMEM  prog_uint16_t profile_temp_00[] =  {100, 300, 370, 390, 410, 420, 430, 430, 430, 430, 430, 430, 430, 430};  //temp per step
PROGMEM  prog_uint16_t profile_time_00[] =  {  0,   0,   0,   0,   0,   0,   0, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_00[]= {  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_00[] =   { 90,  90,  85,  80,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13    
PROGMEM  prog_uint16_t profile_maxtemp_00[] = {540};  //max temp allowed for ct, used only for ror roast methods.
// I know it's only an array of one, but it only works this way, or if I used pointers, and this was easier.

//*********** Profile 01 Definition
prog_uchar profile_name_01[] PROGMEM  = {"R Decaf esp 01  "};  //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_01[] =  {  70,  50,  20,  15,  10,  10,  10,   5,   0,   0,   0,   0,   0,   0};  //ror 
PROGMEM  prog_uint16_t profile_temp_01[] =  {100, 300, 370, 390, 410, 420, 430, 440, 430, 430, 430, 430, 430, 430};  //temp per step
PROGMEM  prog_uint16_t profile_time_01[] =  {  0,   0,   0,   0,   0,   0,   0, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_01[]= {  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_01[] =   { 90,  90,  85,  80,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13    
PROGMEM  prog_uint16_t profile_maxtemp_01[] = {540};  //max temp allowed for ct, used only for ror roast methods.

//***********Profile 02 Definition
prog_uchar profile_name_02[] PROGMEM  = {"R Brazil Alta2  "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_02[] =  {  80,  60,  30,  20,  10,   5,  10,   0,   0,   0,   0,   0,   0,   0};  //ror 
PROGMEM  prog_uint16_t profile_temp_02[] =  {200, 300, 370, 390, 410, 420, 430, 430, 430, 430, 430, 430, 430, 430};  //temp per step
PROGMEM  prog_uint16_t profile_time_02[] =  {  0,   0,   0,   0,   0,   0,   0, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_02[]= {  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_02[] =   { 90,  90,  85,  80,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13  
PROGMEM  prog_uint16_t profile_maxtemp_02[] = {530};   //max temp allowed for ct, used only for ror roast methods.

//***********Profile 03 Definition
prog_uchar profile_name_03[] PROGMEM  = {"T Eth hr04      "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_03[] =   {  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0}; 
PROGMEM  prog_uint16_t profile_temp_03[] =  {150, 150, 250, 330, 410, 445, 480, 500, 520, 525, 525, 525, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_03[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 240, 240, 240,   4,   5,   6};  //time per step
PROGMEM  prog_uint16_t profile_offset_03[]= {  0,   0,   0,  10,  20,  35,  45,  55,  60,  60,  60,  60,  60,  60};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_03[] =   { 75,  75,  70,  70,  65,  60,  55,  55,  50,  50,  50,  50,  50,  50}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,
//time(min)                                             1    2.5  4   5.5   7    10   14   18
//ramp                                                      53    53   23   23  6.7   5   1.3                        
PROGMEM  prog_uint16_t profile_maxtemp_03[] = {540};   //max temp allowed for ct, used only for ror roast methods.                      

//***********Profile 04 Definition
prog_uchar profile_name_04[] PROGMEM  = {"R Eth hr04a      "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_04[] =  {  60,  60,  60, 250, 250, 410, 480, 500, 520, 525, 525, 580, 580, 580};  
PROGMEM  prog_uint16_t profile_temp_04[] =  {250, 330, 410,  60,   1, 240, 180, 240, 180, 240, 240,   5,   6,   7};  
PROGMEM  prog_uint16_t profile_time_04[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 180, 180, 240,   1,   2,   3};  
PROGMEM  prog_uint16_t profile_offset_04[]= {  0,   0,   0,  10,  20,  35,  45,  50,  55,  60,  60,  60,  60,  60};  
PROGMEM  prog_uint16_t profile_fan_04[] =   { 90,  90,  90,  85,  85,  80,  75,  70,  70,  70,  70,  70,  70,  70}; 
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
PROGMEM  prog_uint16_t profile_maxtemp_04[] = {540};   //max temp allowed for ct, used only for ror roast methods.

//***********Profile 05 Definition
prog_uchar profile_name_05[] PROGMEM  = {"T Braz Alta 04   "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_05[] =  {   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0};  //
PROGMEM  prog_uint16_t profile_temp_05[] =  {250, 250, 410, 480, 500, 520, 520, 520, 520, 520, 520, 520, 520, 520};  //temp per step
PROGMEM  prog_uint16_t profile_time_05[] =  { 60,   1, 120, 120, 120, 240, 240, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_05[]= {  0,   0,   0,   0,   0,  00,   0,   0,   0,   0,   0,   0,   0,   0};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_05[] =   { 90,  90,  85,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,
PROGMEM  prog_uint16_t profile_maxtemp_05[] = {540};   //max temp allowed for ct, used only for ror roast methods.
  

//***********Profile 06 Definition
prog_uchar profile_name_06[] PROGMEM  = {"R Eth hr06       "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_06[] =  {150, 150, 250, 330, 410, 445, 480, 500, 520, 525, 540, 540, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_temp_06[] =  {  0,   1,  60,  90,  90,  60,  60, 120, 240, 240, 240,   4,   5,   6};  //temp per step
PROGMEM  prog_uint16_t profile_time_06[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_06[]= {  0,   0,   0,  10,  20,  35,  45,  55,  60,  60,  60,  60,  60,  60};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_06[] =   { 90,  90,  85,  80,  75,  70,  65,  60,  60,  55,  55,  55,  55,  55}; // fan speed profile
//step                                        0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,
PROGMEM  prog_uint16_t profile_maxtemp_06[] = {540};   //max temp allowed for ct, used only for ror roast methods.  

//***********Profile 07 Definition
prog_uchar profile_name_07[] PROGMEM  = {"ror  00        "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_07[] =  {150, 150, 150, 280, 280, 380, 455, 540, 550, 550, 550, 580, 580, 580};  //ROR
PROGMEM  prog_uint16_t profile_temp_07[] =  {  0,   1,   1,  60,   1, 180, 180, 360, 180, 180, 240,   8,   9,  10};  //temp per step
PROGMEM  prog_uint16_t profile_time_07[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_07[]= {  0,   0,   0,  20,  20,  25,  30,  35,  40,  40,  40,  40,  40,  40};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_07[] =   { 90,  90,  90,  85,  85,  80,  75,  70,  70,  70,  70,  70,  70,  70}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
PROGMEM  prog_uint16_t profile_maxtemp_07[] = {540};   //max temp allowed for ct, used only for ror roast methods.

//***********Profile 08 Definition
prog_uchar profile_name_08[] PROGMEM  = {"R temp 00        "};    //Name of this profile, Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_08[] =  {150, 150, 150, 280, 280, 380, 455, 540, 550, 550, 550, 580, 580, 580};  //ROR
PROGMEM  prog_uint16_t profile_temp_08[] =  {  0,   1,   1,  60,   1, 180, 180, 360, 180, 180, 240,   9,  10,  11};  //time per step
PROGMEM  prog_uint16_t profile_time_08[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_08[]= {  0,   0,   0,  20,  20,  25,  30,  35,  40,  40,  40,  40,  40,  40};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_08[] =   { 90,  90,  90,  85,  85,  80,  75,  70,  70,  70,  70,  70,  70,  70}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
PROGMEM  prog_uint16_t profile_maxtemp_08[] = {540};   //max temp allowed for ct, used only for ror roast methods.

//***********Profile 09 Definition
prog_uchar profile_name_09[] PROGMEM  = {"T time/tmp prof  "};    //Max string size is 16 characters
PROGMEM  prog_uint16_t profile_ror_09[] =   {  0, 150, 150, 280, 280, 380, 455, 540, 550, 550, 550, 580, 580, 580};  //ROR
PROGMEM  prog_uint16_t profile_temp_09[] =  {150, 150, 280, 330, 380, 420, 460, 500, 540, 550, 550, 580, 580, 580};  //temperature
PROGMEM  prog_uint16_t profile_time_09[] =  {  0,   1,  60,  90,  90,  90,  90, 180, 180, 180, 240,   1,   2,   3};  //time per step
PROGMEM  prog_uint16_t profile_offset_09[]= {  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0};  // offset correction to temp, per step
PROGMEM  prog_uint16_t profile_fan_09[] =   { 90,  90,  85,  80,  80,  75,  70,  65,  65,  65,  65,  65,  65,  65}; // fan speed profile
//step                                         0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13
PROGMEM  prog_uint16_t profile_maxtemp_09[] = {540};   //max temp allowed for ct, used only for ror roast methods.

