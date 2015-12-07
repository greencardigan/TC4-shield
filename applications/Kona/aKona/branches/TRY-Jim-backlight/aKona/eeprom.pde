//routines to write profiles to eeprom, and read them back

//#include <mcEEPROM.h>
//#include <Wire.h>

/*
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
*/

#include <mcEEPROM.h>       //for accessing eeprom
#include <Wire.h>

//-----------------------------------------------------------------------------------------------------------------------------
//   read profile from eeprom routine
//-----------------------------------------------------------------------------------------------------------------------------

void read_profile(int cnt) {

int k , addr;

addr = PROFILE_ADDR_RX;//init pointer to the start address of the profiles

//increment addr to the address of the profile to read
if (cnt>0) {
  for (int k=0; k < cnt; k++){
   addr += sizeof( myprofile );
   }
  }

   ep.read( addr, (uint8_t*)&myprofile, sizeof( myprofile ) );
   
}


//-----------------------------------------------------------------------------------------------------------------------------
//   write profile routine
//-----------------------------------------------------------------------------------------------------------------------------
void write_profile(int cnt) {
  
 
int ind, addr ;

addr = PROFILE_ADDR_RX;

//increment addr to the address of the profile to read
if (cnt>0) {
  for (int k=0; k < cnt; k++){
    addr += sizeof( myprofile );
    }
  }

//send date from the write structure to the eeprom
ep.write( addr, (uint8_t*)&myprofile, sizeof( myprofile ) );

}

//-----------------------------------------------------------------------------------------------------------------------------
//   write received profile routine
//-----------------------------------------------------------------------------------------------------------------------------
void write_rec_profile(int cnt, byte *pt) {
  
int addr,ind, k ;

addr = PROFILE_ADDR_RX;//init pointer to the start address of the rx profiles

//increment addr to the start of the number of the profile to read
if (cnt>0) {
  for (int k=0; k < cnt; k++){
   addr += sizeof( myprofile );
   }
  }

//send data from the array to the eeprom
ep.write( addr, (uint8_t*) pt, sizeof( myprofile ) );

}

//-----------------------------------------------------------------------------------------------------------------------------
//   read received profile from eeprom routine
//-----------------------------------------------------------------------------------------------------------------------------

void read_rec_profile(int cnt) {

int k , addr;

addr = PROFILE_ADDR_RX;//init pointer to the start address of the profiles

//increment addr to the address of the profile to read
if (cnt>0) {
  for (int k=0; k < cnt; k++){
   addr += sizeof( myprofile );
   }
  }

   ep.read( addr, (uint8_t*)&myprofile, sizeof( myprofile ) );
   
}



