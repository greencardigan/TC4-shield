// serial.pde

/* send data to the serial (USB) port, for logging and display on a PC

*/

#include <konalib.h>

// ------------------------------------------------------------------------
// this routine sends data to the serial port during the roast
 
void serial_send_data()
{
int i;

  Serial.print(tod, DP);

// print ambient
  Serial.print(",");
  Serial.print( t_amb, DP );
  
  Serial.print(",");
  Serial.print( mt, DP );
  Serial.print(",");
  Serial.print( RoRmt, DP );
   
  Serial.print(",");
  Serial.print( ct, DP );
  Serial.print(",");
  Serial.print( RoRct, DP );


  //send setpoint to logfile
  Serial.print(",");
  Serial.print( setpoint, DP );  //send setpoint, to compare setpoint to temps
  

  Serial.print(",");
  Serial.print( step );  //send step number

  Serial.print(",");
  Serial.print( step_timer );  //send step timer 

  Serial.print(",");
  Serial.print( heat, DP );

  Serial.print(",");
  Serial.print( FanSpeed);

  Serial.println();
   
  }

// ------------------------------------------------------------------------
// this routine sends data to the serial port during the roast
 
void serial_send_header()
{
int i;

// send name of profile selected to log file
Serial.print("# profile is ");
for (i = 0; i < 16; i++) {   //send name of this profile to display
	Serial.print(Profile_Name_buffer[i]);
	}

// send roast method to log file
Serial.println();
Serial.print("# roast method is (1=TimeTemp 2=Auto ROR 3= Manual ROR):    ");
Serial.print(roast_method);
Serial.println();

// send max temp to log file
Serial.println();
Serial.print("# Max temp is:    ");
Serial.print(max_temp);
Serial.println();

//send header information to log file
Serial.print("# time,ambient,T0,rate0");
if( NCHAN >= 2 ) Serial.print(",T1,rate1");
Serial.print(",Setpoint,Step,Step Timer,Heat,Fanspeed,Delta T(sp-ct)");
Serial.println();
 
}

// ------------------------------------------------------------------------
// this routine sends the end of roast message to the serial port
 
void serial_send_end()
{

// send end of roast message
Serial.print("#End roast");
 
}



