//compensate.pde
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

/*
routine to compensate for the PID temp setpoint

The PID program has error, which changes with temperature, where the target temp is not matching the setpoint
The routine is intended to reduce the error to a single digit number

Called from PID
*/

//note that the follwoing line is in the main init program, to disable this routing if offset array not equal to 0
//if (Offset_array[6] != 0) {enable_comp = false;} 

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
