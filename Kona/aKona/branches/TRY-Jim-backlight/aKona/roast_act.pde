/*
//roast_act.pde

contains routines used during roast

*/

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

int mspr_key;
int *fly_ptr;

void roast_mode_button_es()
{
  
  if (buttonValue == ESCAPE) { // 
  if ((last_button == true) and (second_last_button == true)){
    *fly_ptr = *fly_ptr+5;
    }
  else {
    *fly_ptr = *fly_ptr+1;
    }
  if (last_button == true) {
    second_last_button = true;
    }
  last_button = true;
  }	
else if (buttonValue == SELECT) {  //
  if ((last_button == true) and (second_last_button == true)) {
    *fly_ptr =*fly_ptr-5;
    }
  else {
    *fly_ptr =*fly_ptr-1;
    }
  if (last_button == true) 
    {second_last_button = true;}
    last_button = true;
    }
   else {
    last_button = false;
    second_last_button = false;
    }
}


// ------------------------------------------------------------------------
// this routine selects the roasting mode for on the fly changes during the roast

void roast_mode_select()

{

boolean picked = false;

roast_mode=0;
while (picked == false) {
        display_roast_menu();  //in display.pde
  	buttonValue = wait_button();       
	if (buttonValue == ESCAPE) {}
        else if (buttonValue == FIFTH) {}
	else if (buttonValue == UP_PLUS) {
		if (roast_mode == 3) {roast_mode=0;}  
		else {roast_mode++;}
		}
	else if (buttonValue == DOWN_MINUS) {
		if (roast_mode == 0) {roast_mode=3;}
		else {roast_mode--;} 
		}
	else if (buttonValue == SELECT) {
		picked = true;
		}
	}
}



// ------------------------------------------------------------------------
// this routine makes on the fly changes during the roast, based on button pushes

void fly_changes()
{
int read_button;
float delta_1, delta_2;
delta_1 = 0;
delta_2 = 0;

buttonValue = get_button();  //read the button, if someone is pushing one

/*
Note that this routine returns a number 0-3, which corresponds to the button pushed
button values are as follows
//new settings, for Jim's board, these lines are for reference only
//#define ESCAPE      0      // Code for Escape switch
//#define SELECT      1      // Code for Select switch
//#define UP_PLUS     2      // Code for PLUS switch
//#define DOWN_MINUS  3      // Code for MINUS switch   */

//check if holding down both down and escape buttons.  This is the button combination to signal end of roast
if ((buttonValue == DOWN_MINUS)) { // hold down_minus button to end roast, note that we need to read the highest code switch first
   if( buttons.readButtons() != 0 ) { // at least one key has changed state
       if( buttons.keyPressed( ESCAPE ) && buttons.keyChanged( ESCAPE ) ) {
        mspr_key = millis(); // mark the time when the key was pressed
      }
    }
  else { // there has been no change in key status, so see if one of them is pressed > 1 sec
      int32_t ms = millis();
      if( buttons.keyPressed( ESCAPE)) {
        if( ms - mspr_key >=  1000 ) {
           mspr_key += 100;  // typematic rate = 100 ms
           if ((last_sel_button == true) and (second_last_sel_button == true))
               {step = NMAX+1;}  //if ESCAPE and DOWN were held down for 3 secs, set step to end, so roast will end.
           if (last_sel_button == true) 
               {second_last_sel_button = true;}
           last_sel_button = true;
         }
      }
    }
  }
   
if (buttonValue == UP_PLUS) { // check if plus was pushed
	if ((last_button == true) and (second_last_button == true))
		{delta_1 = 5;}
	else 
		{delta_1 = 1;}
	if (last_button == true) 
		{second_last_button = true;}
	last_button = true;
	}	
else if (buttonValue == DOWN_MINUS) {  //minus key was pushed
	if ((last_button == true) and (second_last_button == true))
		{delta_1 = -5;}
	else 
		{delta_1 = -1;}
	if (last_button == true) 
		{second_last_button = true;}
	last_button = true;
	}	
if (buttonValue == ESCAPE) { // check if plus was pushed
	if ((last_button == true) and (second_last_button == true))
		{delta_2 = 5;}
	else 
		{delta_2 = 1;}
	if (last_button == true) 
		{second_last_button = true;}
	last_button = true;
	}	
else if (buttonValue == SELECT) {  //minus key was pushed
	if ((last_button == true) and (second_last_button == true))
		{delta_2 = -5;}
	else 
		{delta_2 = -1;}
	if (last_button == true) 
		{second_last_button = true;}
	last_button = true;
	}	

if ((roast_mode == 0) && (roast_method == AUTO_TEMP)) {  //in an temp/time profile, with default variables to change
  if (step_timer > 5) { //dont change if too close to end of this step
    if (delta_1 != 0) {
      target_temp = target_temp + delta_1;
      delta_temp =  (target_temp - setpoint);  //change end temp for this ramp by adjusting slope used in setpoint calcs
      delta_t_per_sec =  (delta_temp / step_timer); //
      }
    if (delta_2 != 0) {
      FanSpeed = FanSpeed + delta_2;  
      }
    }
  }
else if ((roast_mode == 0) && (roast_method == AUTO_ROR)) {  //in a ROR profile, with default variables to change
  if (delta_1 != 0) {
    ROR = ROR + delta_1;  
    delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
		step_timer = 0;  //reset step timer when ROR/slope is changed
		}
  if (delta_2 != 0) {
    target_temp = target_temp + delta_2;  
		}
	}
else if (roast_mode == 1) {  //in mode to change PB and target temp
  if (delta_1 != 0) {
    myPID.Pb = myPID.Pb + delta_1;  
    }
  if (delta_2 != 0) {
    target_temp = target_temp + delta_2;  
    }
  }	
else if (roast_mode == 2) {  //in mode to change I and D
  if (delta_1 != 0) {
    myPID.I = myPID.I + delta_1;  
    }
  if (delta_2 != 0) {
    myPID.D = myPID.D + delta_2;  
    }
  }	

else if (roast_mode == 3) {  //in manual ROR mode, change ROR and target temp
  if (delta_1 != 0) {
    ROR = ROR + delta_1;  
    delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
    step_timer = 0;  //reset step timer when ROR/slope is changed
    }
  if (delta_2 != 0) {
    target_temp = target_temp + delta_2;  
    }
  }


//reset accelerator flags if no button was pushed
if (buttonValue == NOBUTTON) {
  last_button = false;
  second_last_button = false;
  }   	
}

