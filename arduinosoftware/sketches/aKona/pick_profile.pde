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
pick_profile.pde



contains select_profile routine to select which profile to run, and then copy profile data from flash to the arrays which will use the data
to control the roast ROR and temps

*/

//-----------------------------------------------------------------------------------------------------------------------------
//   select profile routine
//-----------------------------------------------------------------------------------------------------------------------------

boolean select_profile()
{
boolean picked = false;

prof_cntr = 0;
//int ind = 0;
boolean return_s = false;  //return true if esc is pushed, otherwise return false if select is pushed

while (picked == false) {  //do until a profile is picked

// check if profile 0 is picked
	buttonValue = 0;
	read_rec_profile(prof_cntr);    //read in profile from eeprom into ram
	display_profile(prof_cntr);     //display profile name and date
	buttonValue = wait_button();  //wait for a button push     
    if (buttonValue == ESCAPE) {
      picked = true;
      return_s = true;
      max_temp = myprofile.maxtemp;
      }
    else if (buttonValue == SELECT) {
        picked = true;
        max_temp = myprofile.maxtemp;
        }
    else if (buttonValue == UP_PLUS) {
        prof_cntr++;
        }
    else if (buttonValue == DOWN_MINUS) {
        prof_cntr--;
        }     

// check for wraparound of prof_cntr  
    if (prof_cntr < 0) {
      prof_cntr = (MAX_PROFILE-1);
      }
    if (prof_cntr > (MAX_PROFILE-1)) {
      prof_cntr = 0;
      }
	
   

    }// end of while picked is false
return (return_s);
}
