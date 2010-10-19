//U_roaster.pde
/*
Put any roaster specific code here, espcially routines to start hardware at start of roast, and turn off at end of roast.

NOTE:  these are defined in konalib.h
ALP_MOTOR_ON   (uint8_t)B00000001
ALP_FLAP_OPEN  (uint8_t)B00000010
ALP_FLAP_CLOSE (uint8_t)B00000100
ALP_FLAP_OPEN_MOTOR_ON (uint8_t)B00000101

*/
#ifdef ALPENROST

//****************************************************************************
void start_alpen (void) {
/*
  // configure the port expander which is used to control the alpenrost
  Wire.beginTransmission( MCP23_ADDR_01 );
  Wire.send( IOCONZ );  // valid command only if BANK = 0, which is true upon reset
  Wire.send( BANK ); // set BANK = 1 if it had been 0 (nothing happens if BANK = 1 already)
  Wire.endTransmission();

  // now, send our IO control byte with assurance BANK = 1
  Wire.beginTransmission( MCP23_ADDR_01 );
  Wire.send( IOCON );
  Wire.send( BANK | SEQOP | DISSLW ); //  banked operation, non-sequential addressing
  Wire.endTransmission();

  // now, set up port A pins for output
  Wire.beginTransmission( MCP23_ADDR_01 );
  Wire.send( IODIRA );
  Wire.send( 0 ); // configure all A pins for output
  Wire.endTransmission();

  Wire.beginTransmission( MCP23_ADDR_01 );
  Wire.send( GPIOA );    //write to GP IO register A to set bits
  Wire.send( ALP_FLAP_CLOSE );  //set bit to close the damper flap
  Wire.endTransmission();

  delay (150);                 //wait a little bit

  Wire.beginTransmission( MCP23_ADDR_01 );
  Wire.send( GPIOA );    //write to GP IO register A to set bits
  Wire.send( 0 );  //turn off damper motor now
  Wire.endTransmission();
  
  
  //close damper again, just to make sure it is really closed
  delay (400);
  Wire.beginTransmission( MCP23_ADDR_01 );
  Wire.send( GPIOA );    //write to GP IO register A to set bits
  Wire.send( ALP_FLAP_CLOSE );  //set bit to close the damper flap
  Wire.endTransmission();

  delay (150);                 //wait a little bit

//  Wire.beginTransmission( MCP23_ADDR_01 );
//  Wire.send( GPIOA );    //write to GP IO register A to set bits
//  Wire.send( 0 );  //turn off damper motor now
//  Wire.endTransmission();

//turn motor on now
  Wire.beginTransmission( MCP23_ADDR_01 );
  Wire.send( GPIOA );    //write to GP IO register A to set bits
  Wire.send( ALP_MOTOR_ON );  //turn on the motor to start roast
  Wire.endTransmission();

*/

digitalWrite(AR_MOTOR_REV_PIN, LOW);   // rev motor direction off
delay (300); 
digitalWrite(AR_MOTOR_ON_PIN, HIGH);   // turn motor on


// close damper, send damper motor a pulse to close the damper door
digitalWrite(AR_FLAP_CLOSE_PIN, HIGH);   // turn flap close on
delay (150);
digitalWrite(AR_FLAP_CLOSE_PIN, LOW);   // turn flap close off

//do it twice, just to make sure it closes
delay (400);
digitalWrite(AR_FLAP_CLOSE_PIN, HIGH);   // turn flap close on
delay (150);
digitalWrite(AR_FLAP_CLOSE_PIN, LOW);   // turn flap close off

}

//****************************************************************************
void end_alpen (void) {
//digitalWrite(AR_MOTOR_ON_PIN, LOW);   // turn motor off
//delay (300);  
//digitalWrite(AR_MOTOR_REV_PIN, HIGH);   // rev motor direction

// open damper, send damper motor a pulse to close the damper door for cooling
digitalWrite(AR_FLAP_OPEN_PIN, HIGH);   // turn flap close on
delay (150);
digitalWrite(AR_FLAP_OPEN_PIN, LOW);   // turn flap close off  
delay (400);
digitalWrite(AR_FLAP_OPEN_PIN, HIGH);   // turn flap close on
delay (150);
digitalWrite(AR_FLAP_OPEN_PIN, LOW);   // turn flap close off  
}

#endif

