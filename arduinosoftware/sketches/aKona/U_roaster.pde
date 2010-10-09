//U_roaster.pde
/*
Put any roaster specific code here, espcially routines to start hardware at start of roast, and turn off at end of roast.


*/
#ifdef ALPENROST

//****************************************************************************
void start_alpen (void) {
  
digitalWrite(AR_MOTOR_ON_PIN, HIGH);   // turn motor on


// close damper, send damper motor a pulse to close the damper door
digitalWrite(AR_FLAP_CLOSE_PIN, HIGH);   // turn flap close on
delay (150);
digitalWrite(AR_FLAP_CLOSE_PIN, LOW);   // turn flap close off

}

//****************************************************************************
void end_alpen (void) {
digitalWrite(AR_MOTOR_ON_PIN, LOW);   // turn motor off
delay (500);  
digitalWrite(AR_MOTOR_REV_PIN, HIGH);   // rev motor direction

// open damper, send damper motor a pulse to close the damper door for cooling
digitalWrite(AR_FLAP_OPEN_PIN, HIGH);   // turn flap close on
delay (150);
digitalWrite(AR_FLAP_OPEN_PIN, LOW);   // turn flap close off  
}

#endif

