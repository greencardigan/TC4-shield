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

//tc4.pde
/*
routines required to read temp data from tc4 card


*/

void init_TC4 () {
  
Wire.begin(); 
adc.setCal( CAL_GAIN, CAL_OFFSET );
amb.init( AMB_FILTER );  // initialize ambient temp filtering
amb.setOffset( AMB_OFFSET );
fT[0].init( MT_FILTER ); // digital filtering on BT
fT[1].init( CT_FILTER ); // digital filtering on ET
fRise[0].init( RISE_FILTER ); // digital filtering for RoR calculation
fRise[1].init( RISE_FILTER ); // digital filtering for RoR calculation
}

// ---------------------------------------------------
// T1, T2 = temperatures x 1000
// t1, t2 = time marks, milliseconds
float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ) {
  int32_t dt = t2 - t1;
  if( dt == 0 ) return 0.0;  // fixme -- throw an exception here?
  float dT = (T2 - T1) * D_MULT;
  float dS = dt * 0.001;
  return ( dT / dS ) * 60.0; // rise per minute
}

// ------------------------------------------------------------------
// routine to read in thermocouple data

void logger()

{

  tod = millis() * 0.001 - start_roast;

  t_amb = amb.getAmbF();
   
  mt = D_MULT*temps[0];
  RoRmt = calcRise( flast[0], ftemps[0], lasttimes[0], ftimes[0] );
  ct = D_MULT*temps[1];
  RoRct = calcRise( flast[1], ftemps[1], lasttimes[1], ftimes[1] );
 
};

// ----------------------------------
void checkStatus( uint32_t ms ) { // this is an active delay loop
  uint32_t tod = millis();
  while( millis() < tod + ms ) {
  }
}

// --------------------------------------------------------------------------
void get_samples() // this function talks to the amb sensor and ADC via I2C
{
  int32_t v;
  TC_TYPE tc;
  float tempC;
  
  for( int j = 0; j < NCHAN; j++ ) { // one-shot conversions on both chips
    adc.nextConversion( j ); // start ADC conversion on channel j
    amb.nextConversion(); // start ambient sensor conversion
    checkStatus( MIN_DELAY ); // give the chips time to perform the conversions
    ftimes[j] = millis(); // record timestamp for RoR calculations
    amb.readSensor(); // retrieve value from ambient temp register
    v = adc.readuV(); // retrieve microvolt sample from MCP3424
    tempC = tc.Temp_C( 0.001 * v, amb.getAmbC() ); // convert to Celsius
    v = round( C_TO_F( tempC ) / D_MULT ); // store results as integers
    temps[j] = fT[j].doFilter( v ); // apply digital filtering for display/logging
    ftemps[j] =fRise[j].doFilter( v ); // heavier filtering for RoR
  }

  tod = millis() * 0.001 - start_roast;

  t_amb = amb.getAmbF();
   
  mt = D_MULT*temps[0];
  RoRmt = calcRise( flast[0], ftemps[0], lasttimes[0], ftimes[0] );
  ct = D_MULT*temps[1];
  RoRct = calcRise( flast[1], ftemps[1], lasttimes[1], ftimes[1] );
 
// Moved from main, except now runs once in init
for( int j = 0; j < NCHAN; j++ ) {
	flast[j] = ftemps[j]; // use previous values for calculating RoR
	lasttimes[j] = ftimes[j];
        }

};
