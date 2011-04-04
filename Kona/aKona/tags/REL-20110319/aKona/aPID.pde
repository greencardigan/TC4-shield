//PID.pde

// *** BSD License ***
// ------------------------------------------------------------------------------------------
// Contributor:  Randy Tsuchiyama
//
// THIS SOFTWARE IS PROVIDED BY THE CONTRIBUTOR "AS IS" AND ANY EXPRESS 
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ------------------------------------------------------------------------------------------
//#include <konalib001.h>  


void init_PID()
{
int ptr;

ptr = PROFILE_ADDR_PID;
//load the PID data from eeprom
ep.read( ptr, (uint8_t*)&myPID, sizeof( myPID ) );  

//if eeprom is not loaded with the PID parameters, then get the parameters from the program memory
if (myPID.init_pattern != 0x5555) { //check to see if eeprom is programmed with the PID info
  myPID.Pb = pgm_read_word_near(flash_Pb);
  myPID.I = pgm_read_word_near(flash_I);  
  myPID.D = pgm_read_word_near(flash_D); 
  myPID.PID_factor = pgm_read_word_near(flash_PID_factor);
  myPID.starttemp = pgm_read_word_near(flash_starttemp);
  myPID.maxtemp = pgm_read_word_near(flash_maxtemp);
  myPID.segment_1 = pgm_read_word_near(flash_segment1);
  myPID.segment_2 = pgm_read_word_near(flash_segment2);
  myPID.seg0_bias = pgm_read_word_near(flash_seg0_bias);
  myPID.seg1_bias = pgm_read_word_near(flash_seg1_bias);
  myPID.seg2_bias = pgm_read_word_near(flash_seg2_bias);
  myPID.seg0_min = pgm_read_word_near(flash_seg0_min);
  myPID.seg1_min = pgm_read_word_near(flash_seg1_min);
  myPID.seg2_min = pgm_read_word_near(flash_seg2_min);
  myPID.startheat = pgm_read_word_near(flash_startheat);
  }
}



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

void PID()
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

error = PID_setpoint - ct + myprofile.offset[step];

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
      if (step == myPID.segment_1) {
         PID_bias = myPID.seg1_bias;
         PID_min = myPID.seg1_min;
         SEG1_flag = true;
         segment++;
         }
      }
   if (SEG2_flag == false)  {
      if (step == myPID.segment_2) {
         PID_bias = myPID.seg2_bias;
         PID_min = myPID.seg2_min;
         SEG2_flag = true;
         segment++;
         }
      }
   }

Proportion = error/myPID.Pb*100; 
Integral = (myPID.I * Sum_errors)/myPID.Pb;
Derivative = myPID.D * (ct-ct_old)/myPID.Pb;

out = ((Proportion + Integral - Derivative)/myPID.PID_factor) + PID_bias;

//Make sure PID result is not out of bounds, set it to boundry limits of pid_min or 100 if it is
if (out > 100) {
   out = 100;
   }
if (out < PID_min) {
   out = PID_min;   //minimum output 
   }

output = out;
}
