//PID.pde

//************************************************************************
// ------------------------- PID routine -------------------------------
//************************************************************************
//logic for calculating the PID output
//
//  error = setpoint - actual temp + offset
//  Proportional term = error/Pb, where Pb is Proportional Band
//  integral = integral + (error*dt)
//  derivative = (error - previous_error)/dt
//  output = (Kp*error) + (Ki*integral) + (Kd*derivative)
//  previous_error = error

//  NOTE: Assume we are running once per second, so dt=1

int PID()
{
//setpoint is the target temperature
//slope (global variable) is the change in temperature in one sec, so it is the D term
//P is Pb
//I is Ki
//D is Kd 

//define and initialize local variables
  int error = 0;
  int previous_error = 0;
  int Sum_errors = 0;
  int out = 0;

  // call routine to perform temp compensation, uses setpoint, calculates compensation and sets PID_setpoint
compensate(setpoint);  
  
// error equals setpoint - control temp + offset, where offset is a fudge factor to compensate for any temp tracking errors.
// note that offset is dependent on the step of the roast

error = PID_setpoint - ct + Offset_array[step];

// technically, intergral should be the sum of all errors, but I am only summing the recent errors, and subtract out errors prior to that.
//logic to subtract out old error value from integral 
error_ptr++;
if (error_ptr > sizeof(error_ptr - 1)) {    //check to see if pointer is past the end of the array
  error_ptr = 0;  //reset index to beginning of array
  }
Sum_errors = Sum_errors - PID_error[error_ptr];  //remove oldest error value from Sum_errors
PID_error[error_ptr] = error; //then add current error to error array

Sum_errors = Sum_errors + error;  //Sum_errors is sum of the latest error values


// check to see what roast segment we are in
// bias and min vary with roast segment, so I am changing things depending on the segment we are in.
if (segment <= NO_SEGMENTS) {
   if (SEG1_flag == false)  {
      if (step == SEGMENT_1) {
         PID_bias = SEG1_BIAS;
         PID_min = SEG1_MIN;
         SEG1_flag = true;
         segment++;
         }
      }
   if (SEG2_flag == false)  {
      if (step == SEGMENT_2) {
         PID_bias = SEG2_BIAS;
         PID_min = SEG2_MIN;
         SEG2_flag = true;
         segment++;
         }
      }
   }

Proportion = error/Pb*100; 
Integral = (I * Sum_errors)/Pb;
Derivative = D * (ct-ct_old)/Pb;

out = ((Proportion + Integral - Derivative)/PID_factor) + PID_bias;

//Make sure PID result is not out of bounds, set it to boundry limits of pid_min or 100 if it is
if (out > 100) {
   out = 100;
   }
if (out < PID_min) {
   out = PID_min;   //minimum output 
   }

output = out;
}
