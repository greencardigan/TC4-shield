
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

//#include <konalib001.h>"
//#include <cButton.h>
int mspr [4];
// ------------------------------------------------------------------------

//this routine waits for the user to push a button switch, and then returns the button switch value
/*
Note that this routine returns a number 0-3, which corresponds to the button pushed
button values are as follows
#define SELECT     0       // set to this value if SELECT is pushed
#define DOWN_MINUS 1       // set to this value if Minus is pushed (was MINUS in 4 button setup)
#define UP_PLUS    2       // set to this value if Plus is pushed (was PLUS in 4 button setup)
#define ESCAPE     3       // set to this value if SELECT is pushed

*/

int wait_button ()
{
  
//int read_button;
int button_pushed;
boolean pushed;

pushed = false;
button_pushed = NOBUTTON;
//read_button =0;
while (pushed == false) { // wait for a button to be pushed

  // first, check and see if at least one button has changed state
  if( buttons.readButtons() != 0 ) {
    for( int i = 0; i < 4; i++ ) {
      if( buttons.keyPressed( i ) && buttons.keyChanged( i ) ) {
        mspr[i] = millis(); // mark the time when the key was pressed
        button_pushed = i;
        pushed = true;
      }
    }
  }
 }  
return button_pushed;  
}
// ------------------------------------------------------------------------
//this routine sees if a button was pushed, returns the button value

int get_button (void){
  
//int read_button;
int button_pushed;
boolean pushed;


//read_button =0;
button_pushed = NOBUTTON;

/*
Note that this routine returns a number 0-3, which corresponds to the button pushed
button values are as follows
#define SELECT     0       // set to this value if SELECT is pushed
#define DOWN_MINUS 1       // set to this value if Minus is pushed (was MINUS in 4 button setup)
#define UP_PLUS    2       // set to this value if Plus is pushed (was PLUS in 4 button setup)
#define ESCAPE     3       // set to this value if SELECT is pushed

*/

  if( buttons.readButtons() != 0 ) { // at least one key has changed state
    for( int bi = 0; bi < 4; bi++ ) {
      if( buttons.keyPressed( bi ) && buttons.keyChanged( bi ) ) {
        mspr[bi] = millis(); // mark the time when the key was pressed
        button_pushed = bi;
      }
    }
  }
  else //if( buttons.anyPressed() ) {  // there has been no change in key status, so see if one of them is pressed > 1 sec
    {
      for( int bi = 0; bi< 4; bi++ ) {
      int32_t ms = millis();
      if( buttons.keyPressed( bi )) {
        if( ms - mspr[bi] >=  1000 ) {
           button_pushed = bi;
           mspr[bi] += 100;  // typematic rate = 100 ms
           }
         }
      }
  }
return button_pushed;  
}
/*
  if( buttons.readButtons() != 0 ) { // at least one key has changed state
    for( int i = 0; i < 4; i++ ) {
      if( buttons.keyPressed( i ) && buttons.keyChanged( i ) ) {
        mspr[i] = millis(); // mark the time when the key was pressed
        Serial.println( i );
        buttonAction( i );
      }
    }
  }
  else { // there has been no change in key status, so see if one of them is pressed > 1 sec
    for( int i = 0; i< 4; i++ ) {
      int32_t ms = millis();
      if( buttons.keyPressed( i )) {
        if( ms - mspr[i] >=  1000 ) {
          buttonAction( i );
          mspr[i] += 100;  // typematic rate = 100 ms
        }
      }
    }
  }

*/





