//routines to write profiles to eeprom, and read them back

#include <mcEEPROM.h>       //for accessing eeprom
#include <Wire.h>

//-----------------------------------------------------------------------------------------------------------------------------
//   write profile routine
//-----------------------------------------------------------------------------------------------------------------------------
void write_profile(int cnt, byte *pt) {
  
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



