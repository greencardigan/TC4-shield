
#ifdef EEROM


#include <mcEEPROM.h>
#include <Wire.h>

struct profile {
  char name[16];
  int ror[NMAX];
  int temp[NMAX];
  int time[NMAX];
  int offset[NMAX];
  int speed[NMAX];
  int max_temp;
};



profile myprofile;

struct infoBlock {
  char PCB[40]; // identifying information for the board
  char version[16];
  float cal_gain;  // calibration factor of ADC at 50000 uV
  int16_t cal_offset; // uV, probably small in most cases
  float T_offset; // temperature offset (Celsius) at 0.0C (type T)
  float K_offset; // same for type K
};

infoBlock infotx = {
  "TC4_SHIELD",
  "1.06RE",
  1.00166,
  -3,
  -0.50,
  -0.50
};

infoBlock inforx = {
  "",
  "",
  0.0,
  0,
  0.0,
  0.0
};

mcEEPROM ep;

void read_profile(int i) {
  
 uint16_t ptr = PROFILE_ADDR_01;

if (i>0) {
  for (int k=0; k < i; k++){
   ptr += sizeof( myprofile );}
  }

   ep.read( ptr, (uint8_t*)&myprofile, sizeof( myprofile ) );

  ep.write( 0, (uint8_t*) &infotx, sizeof( infotx ) );
  ep.read( 0, (uint8_t*) &inforx, sizeof( inforx ) );
  
  Serial.begin(57600);
  Serial.println(inforx.PCB);
  Serial.println(inforx.version);
  Serial.println(inforx.cal_gain, DEC);
  Serial.println(inforx.cal_offset);
  Serial.println(inforx.T_offset);
  Serial.println(inforx.K_offset);
  
}

#endif


