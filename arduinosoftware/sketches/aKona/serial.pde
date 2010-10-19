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

  Serial.print(",");
  Serial.print( ROR, DP );


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
Serial.print("# Time,Ambient,MT,ROR MT,CT,ROR CT,Setpoint,Step,Step Timer,Heat,Fanspeed,ROR,Delta T(sp-ct)");
Serial.println();
 
}

// ------------------------------------------------------------------------
// this routine sends the end of roast message to the serial port
 
void serial_send_end()
{

// send end of roast message
Serial.print("#End roast");
 
}



