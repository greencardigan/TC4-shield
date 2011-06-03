// appbase.pde

// demonstration sketch for library class appBase

#include <Wire.h>
#include <TC4app.h>
#include <cADC.h>
#include <mcEEPROM.h>
#include <cLCD.h>
#include <cButton.h>
#include <TCbase.h>

#define FTEMP 10 // filtering level on direct temperature readings
#define FRISE 85 // filtering level on temp values used to compute rise
#define FROR 80 // post-filtering on stream of RoR values
#define FAMB 85
#define BANNER "appBase Demo"

// these must be defined in the main program and passed to the application class
TypeK tc; // required
cButtonPE16 buttons; // optional
cLCD lcd; // optional, or may be LiquidCrystal class

// the app constructor must identify a sensor that derives from TCbase
appBase app( &tc );

void setup() {
  app.setBanner( BANNER ); // optional; limit to 16 characters of text
  app.setLCD ( &lcd, 16, 2 ); // optional;
  app.setButtons( &buttons ); // optional;
  //app.setBaud( 115200 ); // optional; default is 57600 if not set
  //app.setActiveChannels(1,2,4,3); // optional; use only to override default of 1,2,0,0
  app.setAmbFilter( FAMB ); // optional; required only if override of default (80) is desired
  app.initTempFilters(FTEMP,FTEMP,FTEMP,FTEMP); // required; override with non-default values if desired (default 10)
  app.initRiseFilters(FRISE,FRISE,FRISE,FRISE); // required; override with non-default values if desired (default 85)
  app.initRoRFilters(FROR,FROR,FROR,FROR); // required; override with non-default values if desired (default 80)
  app.start(); // required (last); can use this to override (lengthen) the default cycle time
}

void loop() {
  app.run();
}



