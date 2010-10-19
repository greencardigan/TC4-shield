//button.pde
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
routines to read button pushes
all logic to read the buttons is here, except in one place in mode.pde at the beginning of
fly_changes().

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
	read_button = analogRead (ESC_PLUS_BUTTON);
	if (read_button > ANYKEY) { 
		read_button = analogRead (ESC_PLUS_BUTTON);  
		if (read_button > ESC_VALUE) {  //RIGHT key was pushed
			button_pushed = ESCAPE;
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
		
	read_button = analogRead (SELECT_BUTTON);  
	if (read_button > SELECT_VALUE) { 
		read_button = analogRead (SELECT_BUTTON);  
		if (read_button > SELECT_VALUE) {  //LEFT key was pushed
			button_pushed = SELECT;
			pushed = true;
			}
		}  
		
	read_button = analogRead (FIFTH_BUTTON);  
	if (read_button > FIFTH_VALUE) { 
		read_button = analogRead (FIFTH_BUTTON);  
		if (read_button > FIFTH_VALUE) {  //FIFTH key was pushed
			button_pushed = FIFTH;
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
read_button = analogRead (ESC_PLUS_BUTTON);  
if (read_button > ANYKEY) { 
    read_button = analogRead (ESC_PLUS_BUTTON);  
    if (read_button > ESC_VALUE) {  //RIGHT key was pushed
		button_pushed = ESCAPE;
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
	
read_button = analogRead (SELECT_BUTTON);  
if (read_button > SELECT_VALUE) { 
	read_button = analogRead (SELECT_BUTTON);  
	if (read_button > SELECT_VALUE) {  //LEFT key was pushed
		button_pushed = SELECT;
		pushed = true;
		}
	}  

/*
read_button = analogRead (FIFTH_BUTTON);  
if (read_button > FIFTH_VALUE) { 
	read_button = analogRead (FIFTH_BUTTON);  
	if (read_button > FIFTH_VALUE) {  //FIFTH key was pushed
		button_pushed = FIFTH;
		pushed = true;
		}
	}  
*/

return button_pushed;  

}


