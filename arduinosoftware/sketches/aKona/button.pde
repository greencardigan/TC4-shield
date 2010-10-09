//button.pde
/*
routines to read button pushes

*/

#include <konalib.h>"

// ------------------------------------------------------------------------

//this routine waits for the user to push a button switch, and then returns the button switch value

int wait_button ()
{
  
int read_button;
int button_pushed;
boolean pushed;

pushed = false;
read_button =0;
while (pushed == false) { // wait for a button to be pushed
	read_button = analogRead (RIGHT_PLUS_BUTTON);
	if (read_button > ANYKEY) { 
		read_button = analogRead (RIGHT_PLUS_BUTTON);  
		if (read_button > RIGHT_VALUE) {  //RIGHT key was pushed
			button_pushed = RIGHT;
			pushed = true;
			}
		else if (read_button > PLUS_VALUE) {  //plus key pushed, it is lowest one
			button_pushed = UP_PLUS;
			pushed = true;
			}
		} 
	read_button = analogRead (MINUS_BUTTON);  
	if (read_button > MINUS_VALUE) { 
		read_button = analogRead (MINUS_BUTTON);  
		if (read_button > MINUS_VALUE) {  //esc key was pushed
			button_pushed = DOWN_MINUS;
			pushed = true;
			}
		}   
		
	read_button = analogRead (LEFT_BUTTON);  
	if (read_button > LEFT_VALUE) { 
		read_button = analogRead (LEFT_BUTTON);  
		if (read_button > LEFT_VALUE) {  //LEFT key was pushed
			button_pushed = LEFT;
			pushed = true;
			}
		}  
		
	read_button = analogRead (SELECT_BUTTON);  
	if (read_button > SELECT_VALUE) { 
		read_button = analogRead (SELECT_BUTTON);  
		if (read_button > SELECT_VALUE) {  //SELECT key was pushed
			button_pushed = SELECT;
			pushed = true;
			}
		}
}
delay (DEBOUNCE);
return button_pushed;  
}
// ------------------------------------------------------------------------
//this routine sees if a button was pushed, returns the button value

int get_button (void){
  
int read_button;
int button_pushed;
boolean pushed;

read_button =0;
button_pushed = NOBUTTON;
read_button = analogRead (RIGHT_PLUS_BUTTON);  
if (read_button > ANYKEY) { 
    read_button = analogRead (RIGHT_PLUS_BUTTON);  
    if (read_button > RIGHT_VALUE) {  //RIGHT key was pushed
		button_pushed = RIGHT;
		pushed = true;
        }
    else if (read_button > PLUS_VALUE) {  //plus key pushed, it is lowest one
        button_pushed = UP_PLUS;
        pushed = true;
        }
    } 
read_button = analogRead (MINUS_BUTTON);  
if (read_button > MINUS_VALUE) { 
    read_button = analogRead (MINUS_BUTTON);  
    if (read_button > MINUS_VALUE) {  //esc key was pushed
		button_pushed = DOWN_MINUS;
		pushed = true;
        }
    }   
	
read_button = analogRead (LEFT_BUTTON);  
if (read_button > LEFT_VALUE) { 
	read_button = analogRead (LEFT_BUTTON);  
	if (read_button > LEFT_VALUE) {  //LEFT key was pushed
		button_pushed = LEFT;
		pushed = true;
		}
	}  
	
read_button = analogRead (SELECT_BUTTON);  
if (read_button > SELECT_VALUE) { 
	read_button = analogRead (SELECT_BUTTON);  
	if (read_button > SELECT_VALUE) {  //SELECT key was pushed
		button_pushed = SELECT;
		pushed = true;
		}
	}  

return button_pushed;  

}


