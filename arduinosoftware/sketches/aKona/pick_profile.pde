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


void select_profile()
{
boolean picked = false;
int cntr = 0;
int ind = 0;


while (picked == false) {  //do until a profile is picked

// check if profile 0 is picked
	buttonValue = 0;
	
	switch (cntr){
		case (0):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				#ifdef EEROM
				//read_profile(ind);
				#endif
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_00 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {}
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_00);
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_00 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_00 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_00 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_00 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_00 + ind);
					}	
				}
			else if (buttonValue == UP_PLUS) {
				cntr++;
				}
			else if (buttonValue == DOWN_MINUS) {
				cntr=(NO_PROFILES - 1); 
				}     
            break;
			   
// check if profile 1 is picked
		case (1):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_01 + ind);
			}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {}
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_01);
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_01 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_01 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_01 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_01 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_01 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) { cntr++; }
			else if (buttonValue == DOWN_MINUS) { cntr--; }        
	        break;
			   
	//see if profile 02
		case (2):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_02 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) { }
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_02);
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_02 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_02 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_02 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_02 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_02 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) { cntr++;}
			else  if (buttonValue == DOWN_MINUS) { cntr--; }        
            break;
			
	//see if profile 03
		case (3):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_03 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) { }
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_03);
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_03 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_03 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_03 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_03 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_03 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) { cntr++; }
			else  if (buttonValue == DOWN_MINUS) {cntr--; }      
            break;            

	//see if profile 04
		case (4):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_04 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {}
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_04);				
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_04 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_04 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_04 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_04 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_04 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) {	cntr++;	}
			else  if (buttonValue == DOWN_MINUS) { cntr--; }        
            break;
			
	//see if profile 05
		case (5):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_05 + ind);
			}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {}
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_05);				
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_05 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_05 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_05 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_05 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_05 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) { cntr++; }
			else  if (buttonValue == DOWN_MINUS) { cntr--; }        
            break;
			
	//see if profile 06
		case (6):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_06 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {}
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_06);
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_06 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_06 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_06 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_06 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_06 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) {   cntr++;        }
			else  if (buttonValue == DOWN_MINUS) { cntr--;        }        
			break;
			
	//see if profile 07
		case (7):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_07 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {  }
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_07);				
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_07 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_07 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_07 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_07 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_07 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) {cntr++;   }
			else  if (buttonValue == DOWN_MINUS) { cntr--; }        
            break;
			
	//see if profile 08
		case (8):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_08 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {    }
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_08);				
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_08 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_08 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_08 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_08 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_08 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) {  cntr++;  }
			else  if (buttonValue == DOWN_MINUS) { cntr--; }        
            break;

	//see if profile 09
		case (9):
			for (ind = 0; ind < 16; ind++) {   //send name of this profile to display
				Profile_Name_buffer[ind] = pgm_read_byte_near(profile_name_09 + ind);
				}
			display_profile(cntr);
			buttonValue = wait_button();       
			if (buttonValue == FIFTH) {}
                        else if (buttonValue == ESCAPE) {}
			else if (buttonValue == SELECT) {
				picked = true;
				max_temp = pgm_read_word_near(profile_maxtemp_09);				
				for (ind = 0; ind < NMAX; ind++) {  
					ror_array[ind] = pgm_read_word_near(profile_ror_09 + ind);
					Temp_array[ind] = pgm_read_word_near(profile_temp_09 + ind);
					Time_array[ind] = pgm_read_word_near(profile_time_09 + ind);
					Offset_array[ind] = pgm_read_word_near(profile_offset_09 + ind);
					Speed_array[ind] = pgm_read_word_near(profile_fan_09 + ind);
					}
				}
			else if (buttonValue == UP_PLUS) { cntr=0; } //wraparound 
			else  if (buttonValue == DOWN_MINUS) { cntr--; }        
            break;
			
	// Make sure cntr does not get messed up
		default:   
			cntr = 0;
			break;
		} // end of switch-case 
	} // end of while picked is false

}
