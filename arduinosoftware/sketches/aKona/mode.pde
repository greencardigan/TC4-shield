// ------------------------------------------------------------------------
// this routine selects the roasting mode for on the fly changes during the roast

void roast_mode_select()

{

boolean picked = false;

roast_mode=0;
while (picked == false) {
        display_roast_menu();  //in display.pde
  	buttonValue = wait_button();       
	if (buttonValue == RIGHT) {}
        else if (buttonValue == LEFT) {}
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

   buttonValue = get_button(); 
   if (buttonValue == SELECT) {// hold down select button to end roast
     display_ask_end();
     //step = NMAX+1;
     			if ((last_sel_button == true) and (second_last_sel_button == true))
				{step = NMAX+1;}  //if select was held down for 3 secs, set step to end, so roast will end.
			if (last_sel_button == true) 
				{second_last_sel_button = true;}
			last_sel_button = true;
			}

switch (roast_mode){
	case (0):  //change target temp for this ramp, or fanspeed for this ramp for this case   
		if (buttonValue == UP_PLUS) { // check if plus was pushed
			if (roast_method == AUTO_TEMP) {
				if (step_timer > 5) { //dont change if too close to end of this step
					if ((last_button == true) and (second_last_button == true)) {
						target_temp = target_temp + 5;
						delta_temp =  (target_temp - setpoint);  //change end temp for this ramp by adjusting slope used in setpoint calcs
						delta_t_per_sec =  (delta_temp / step_timer); //
						}
					else {
						target_temp = target_temp + 1;
						delta_temp =  (target_temp - setpoint);  //
						delta_t_per_sec =  (delta_temp / step_timer); //change end temp for this ramp by adjusting slope used in setpoint calcs
					     }
					}	
				}
			else if (roast_method == AUTO_ROR) {
				if ((last_button == true) and (second_last_button == true)) {
					ROR = ROR + 5;
					delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
					step_timer = 0;  //reset step timer when ROR/slope is changed
					//step_st_time = millis() * 0.001;     //set new start time since ramp change
					//step_st_temp = setpoint;     //set new start temp since ramp change
					}
				else {
					ROR = ROR + 1;
					delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
					step_timer = 0;  //reset step timer when ROR/slope is changed
					//step_st_time = millis() * 0.001;     //set new start time since ramp change
					//step_st_temp = setpoint;     //set new start temp since ramp change
					}	
				}
			if (last_button == true) 
			  {second_last_button = true;}
		      last_button = true;
			}	
		else if (buttonValue == DOWN_MINUS) {  //minus key was pushed
			if (roast_method == AUTO_TEMP) {
				if (step_timer > 5) { //dont change if too close to end of this step
					if ((last_button == true) and (second_last_button == true)) {
						target_temp = target_temp - 5;
						delta_temp =  (target_temp - setpoint);  //
						delta_t_per_sec =  (delta_temp / step_timer); //change end temp for this ramp by adjusting slope used in setpoint calcs
						}
					else {
						target_temp = target_temp - 1;
						delta_temp =  (target_temp - setpoint);  //
						delta_t_per_sec =  (delta_temp / step_timer); //change end temp for this ramp by adjusting slope used in setpoint calcs
						}
					}
				}	
			else if (roast_method == AUTO_ROR) {
				if ((last_button == true) and (second_last_button == true)) {
					ROR = ROR - 5;
					delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
					step_timer = 0;  //reset step timer when ROR/slope is changed
					//step_st_time = millis() * 0.001;     //set new start time since ramp change
					//step_st_temp = setpoint;     //set new start temp since ramp change
					}
				else {
					ROR = ROR - 1;
					delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
					step_timer = 0;  //reset step timer when ROR/slope is changed
					//step_st_time = millis() * 0.001;     //set new start time since ramp change
					//step_st_temp = setpoint;     //set new start temp since ramp change
					}
				}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
		else if (buttonValue == RIGHT) { // 
			if ((last_button == true) and (second_last_button == true))
				{FanSpeed = FanSpeed + 5;}
			else {FanSpeed = FanSpeed + 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
		}	
		else if (buttonValue == LEFT) {  //
			if ((last_button == true) and (second_last_button == true))
				{FanSpeed = FanSpeed - 5;}
			else {FanSpeed = FanSpeed - 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
		else {
			last_button = false;
			second_last_button = false;
			}
		//buttonValue = 0;
		break;
                	
	case (1):  //Change Pb and FanSpeed for this case
		//buttonValue = get_button();    
		if (buttonValue == UP_PLUS) { // check if plus was pushed
			if ((last_button == true) and (second_last_button == true))
				{Pb = Pb + 5;}
			else 
				{Pb = Pb + 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
		}	
		else if (buttonValue == DOWN_MINUS) {  //minus key was pushed
			if ((last_button == true) and (second_last_button == true)) 
				{Pb = Pb - 5;}
			else 
				{Pb = Pb - 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
		else if (buttonValue == RIGHT) { // Escape key was pushed
			if ((last_button == true) and (second_last_button == true))
				{FanSpeed = FanSpeed + 5;}
			else {FanSpeed = FanSpeed + 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
		}	
		else if (buttonValue == LEFT) {  //SELECT key was pushed
			if ((last_button == true) and (second_last_button == true))
				{FanSpeed = FanSpeed - 5;}
			else {FanSpeed = FanSpeed - 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
        else {
            last_button = false;
            second_last_button = false;
            }
        //buttonValue = 0;
		break;

	case (2):  //change I and D for this case
		//buttonValue = get_button();    
		if (buttonValue == UP_PLUS) { // check if plus was pushed
			if ((last_button == true) and (second_last_button == true))
				{I = I + 5;}
			else 
				{I = I + 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
		}	
		else if (buttonValue == DOWN_MINUS) {  //minus key was pushed
			if ((last_button == true) and (second_last_button == true)) 
				{I = I - 5;}
			else 
				{I = I - 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
		else if (buttonValue == RIGHT) { // RIGHT key was pushed
			if ((last_button == true) and (second_last_button == true))
				{D = D + 5;}
			else {D = D + 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
		}	
		else if (buttonValue == LEFT) {  //LEFT key was pushed
			if ((last_button == true) and (second_last_button == true))
				{D = D - 5;}
			else {D = D - 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
        else {
            last_button = false;
            second_last_button = false;
            }
        //buttonValue = 0;
		break;

	case (3):  //Change ROR and FanSpeed during roast
		//buttonValue = get_button();    
		if (buttonValue == UP_PLUS) { // check if plus was pushed
			if ((last_button == true) and (second_last_button == true)) {
				ROR = ROR + 5;
				delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
                                step_timer = 0;  //reset step timer when ROR/slope is changed
				//step_st_time = millis() * 0.001;     //set new start time since ramp change
				//step_st_temp = setpoint;     //set new start temp since ramp change
  				}
			else {
				ROR = ROR + 1;
                                delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
				step_timer = 0;  //reset step timer when ROR/slope is changed
				//step_st_time = millis() * 0.001;     //set new start time since ramp change
				//step_st_temp = setpoint;     //set new start temp since ramp change
				}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
		}	
		else if (buttonValue == DOWN_MINUS) {  //minus key was pushed
			if ((last_button == true) and (second_last_button == true)) {
				ROR = ROR - 5;
                                delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
                                step_timer = 0;  //reset step timer when ROR/slope is changed
				//step_st_time = millis() * 0.001;     //set new start time since ramp change
				//step_st_temp = setpoint;     //set new start temp since ramp change
				}
			else {
				ROR = ROR - 1;
                                delta_t_per_sec = (ROR / 60);   //convert ROR from deg per min to slope in deg per second
				step_timer = 0;  //reset step timer when ROR/slope is changed
				//step_st_time = millis() * 0.001;     //set new start time since ramp change
				//step_st_temp = setpoint;     //set new start temp since ramp change
				}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
		else if (buttonValue == RIGHT) { // check if escape was pushed
			if ((last_button == true) and (second_last_button == true))
				{FanSpeed = FanSpeed + 5;}
			else {FanSpeed = FanSpeed + 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
		}	
		else if (buttonValue == LEFT) {  //minus key was pushed
			if ((last_button == true) and (second_last_button == true))
				{FanSpeed = FanSpeed - 5;}
			else {FanSpeed = FanSpeed - 1;}
			if (last_button == true) 
				{second_last_button = true;}
			last_button = true;
			}
        else {
            last_button = false;
            second_last_button = false;
            }
        //buttonValue = 0;
		break;
	}  //end case
 
   	
}
