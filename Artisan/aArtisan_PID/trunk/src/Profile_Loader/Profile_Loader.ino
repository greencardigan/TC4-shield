// This sketch writes roast profile information to EEPROM
// WARNING:  it will overwrite existing profile information

// Author:  Brad Collins

// Open a serial monitor (19200 baud) screen in the Arduino IDE to confirm that the values were
// correctly written and can be read back from the EEPROM.

#include <mcEEPROM.h>
#include <Wire.h>

mcEEPROM ep;

void setup() {

Serial.begin(19200);

int profile_size = 400; // number of bytes in EEPROM allocated for each profile
int start_of_profiles = 1024; // address of first profile in EEPROM

//////////////////////////////////////////////////////////////////////////////////////////
// PROFILE DATA //////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////


int profile_number = 1;
int profile_type = 1;
char profile_CorF = 'C';
char profile_name[40] = "PROFILE 1";
char profile_description[80] = "Description of Profile 1";
int profile_time[50] = { 0.00,160.00,180.00,200.00,220.00,240.00,400.00,420.00,440.00,460.00,480.00,720.00,960.00, 0};
int profile_temp[50] = {25.00,117.00,127.00,136.00,144.00,151.00,193.00,197.00,201.00,204.00,207.00,232.00,257.00, 0};


/*
int profile_number = 2;
int profile_type = 1;
char profile_CorF = 'C';
char profile_name[40] = "PROFILE 2";
char profile_description[80] = "Description of Profile 2";
int profile_time[50] = { 0, 300, 600, 900, 1200, 0};
int profile_temp[50] = {25, 150, 205, 233, 261, 0};
*/

//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////
// WRITE PROFILE //////////////
///////////////////////////////

int profile_ptr = (profile_number - 1) * profile_size + start_of_profiles; // set EEPROM address to start of this profile

ep.write( profile_ptr, (uint8_t*)&profile_number, sizeof(profile_number) ); // write to EEPROM
profile_ptr += sizeof(profile_number);
ep.write( profile_ptr, (uint8_t*)&profile_type, sizeof(profile_type) );
profile_ptr += sizeof(profile_type);
ep.write( profile_ptr, (uint8_t*)&profile_CorF, sizeof(profile_CorF) );
profile_ptr += sizeof(profile_CorF);
ep.write( profile_ptr, (uint8_t*)&profile_name, sizeof(profile_name) );
profile_ptr += sizeof(profile_name);
ep.write( profile_ptr, (uint8_t*)&profile_description, sizeof(profile_description) );
profile_ptr += sizeof(profile_description);
ep.write( profile_ptr, (uint8_t*)&profile_time, sizeof(profile_time) );
profile_ptr += sizeof(profile_time);
ep.write( profile_ptr, (uint8_t*)&profile_temp, sizeof(profile_temp) );
profile_ptr += sizeof(profile_temp);

//Serial.println(profile_ptr); // show pointer value for end of profile

delay(500);


////////////////////////////////////
// READ PROFILE BACK ///////////////
////////////////////////////////////


int num;
int type;
char CorF;
char name[40];
char desc[80];
int time[50];
int temp[50];

profile_ptr = (profile_number - 1) * profile_size + start_of_profiles;  // set EEPROM address to start of this profile

ep.read( profile_ptr, (uint8_t*)&num, sizeof(num) ); // read profile from EEPROM
profile_ptr += sizeof(num);
ep.read( profile_ptr, (uint8_t*)&type, sizeof(type) );
profile_ptr += sizeof(type);
ep.read( profile_ptr, (uint8_t*)&CorF, sizeof(CorF) );
profile_ptr += sizeof(CorF);
ep.read( profile_ptr, (uint8_t*)&name, sizeof(name) );
profile_ptr += sizeof(name);
ep.read( profile_ptr, (uint8_t*)&desc, sizeof(desc) );
profile_ptr += sizeof(desc);
ep.read( profile_ptr, (uint8_t*)&time, sizeof(time) );
profile_ptr += sizeof(time);
ep.read( profile_ptr, (uint8_t*)&temp, sizeof(temp) );
profile_ptr += sizeof(temp);

//Serial.println(profile_ptr); // show pointer value for end of profile

Serial.println(num); // serial print profile
Serial.println(type);
Serial.println(CorF);
Serial.println(name);
Serial.println(desc);

int i;
for (i = 0; i < sizeof(time)/2; i++) {
  Serial.print(time[i]);
  Serial.print("\t");
}
Serial.println("");

for (i = 0; i < sizeof(time)/2; i++) {
  Serial.print(temp[i]);
  Serial.print("\t");
}
Serial.println("");

}

void loop() {
}

  
  
