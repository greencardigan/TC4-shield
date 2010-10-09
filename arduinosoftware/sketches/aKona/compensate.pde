//compensate.pde
/*
routine to compensate for the PID temp setpoint

The PID program has error, which changes with temperature, where the target temp is not matching the setpoint
The routine is intended to reduce the error to a single digit number


*/

//include "user.h"

//boolean enable_comp = false;

// ------------------------------------------------------------------------

//input is setpoint
//output is PID_setpoint

void compensate (float sp)
{
if (enable_comp == true) {
	if (sp < 280) {
		PID_setpoint = sp;
		}
	else if ((sp < 300)) {  //setpoint between 300 and 400
		PID_setpoint = ((sp-280)*0.2) + sp;
		}
	else if ((sp < 400)) {  //setpoint between 300 and 400
		PID_setpoint = ((sp-300)*0.4) + sp + 4;
		}
	else if ((sp < 500)) {   //setpoint between 400 and 500
		PID_setpoint = ((sp-400)*0.2) + sp + 40;
		}
	else {                      // //setpoint >500
		PID_setpoint = sp+60;
		}
	}
else {
	PID_setpoint = sp;
	}
}
