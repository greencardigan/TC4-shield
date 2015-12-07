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

        my_out.port_A_out(ALP_FLAP_CLOSE_MOTOR_ON);
        delay (150);
        my_out.port_A_out(ALP_MOTOR_ON); // turn motor on, flap motor off
        delay (300);
        my_out.port_A_out(ALP_FLAP_CLOSE_MOTOR_ON);
        delay (150);
        my_out.port_A_out(ALP_MOTOR_ON); // turn motor on, flap motor off

}

//****************************************************************************
void end_alpen (void) {
 
        my_out.port_A_out(ALP_FLAP_OPEN_MOTOR_ON);
        delay (150);
        my_out.port_A_out(ALP_MOTOR_ON); // turn motor on, flap motor off
        delay (300);
        my_out.port_A_out(ALP_FLAP_OPEN_MOTOR_ON);
        delay (150);
        my_out.port_A_out(ALP_MOTOR_ON); // turn motor on, flap motor off
 
}

#endif

