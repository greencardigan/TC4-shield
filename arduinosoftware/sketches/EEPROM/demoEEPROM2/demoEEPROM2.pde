// demo program for mcEEPROM library
// Jim Gallt
// Aug. 2, 2010

#include <mcEEPROM.h>
#include <Wire.h>

int tod;
uint16_t nr, nw;
mcEEPROM ep;

#define PTR 0xA0A0
uint16_t ptr;

double xx = 2.71828;
double yy = 0;

char tstr[] = "Now_is_the time for all good men to come to the aid of their country.";
//char tstr[] = "0123456789ABCDEF0123456789ABCDEF";
char rstr[128];
float x = 3.14159;
//float x = 2.71828;
float y = 0.0;
//int it = 1234;
int it = -1234;
int ir = 0;

unsigned uit = 4567;
unsigned uir = 0;

long lit = -1234567;
long lir = 0;

unsigned long ulit = 7654321;
unsigned long ulir = 0;


void setup() {
  Serial.begin(57600);
  delay(1000);
  
// Test read/write of floats  
 
  ptr = PTR;
  Serial.print("Writing float @ 0x"); Serial.println( ptr, HEX );
  tod = millis();
  nw = ep.write( ptr, &x );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");

  Serial.println("Reading float..");
  tod = millis();
  nr = ep.read( ptr, &y );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");
  ptr+= nw;
  
  Serial.print( nw ); Serial.print(",");
  Serial.println( x );
  Serial.print( nr ); Serial.print(",");
  Serial.println( y ); 
  Serial.println();

// Test read/write of double  
 
  Serial.print("Writing double @ 0x"); Serial.println( ptr, HEX );
  tod = millis();
  nw = ep.write( ptr, &xx );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");

  Serial.println("Reading double..");
  tod = millis();
  nr = ep.read( ptr, &yy );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");
  ptr+= nw;
  
  Serial.print( nw ); Serial.print(",");
  Serial.println( xx );
  Serial.print( nr ); Serial.print(",");
  Serial.println( yy ); 
  Serial.println();

// Test read/write of strings
  
  Serial.print("Writing string @ 0x"); Serial.println( ptr, HEX );
  tod = millis();
  nw = ep.write( ptr, tstr );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");

  Serial.println("Reading string..");
  tod = millis();
  nr = ep.read( ptr, rstr, sizeof(rstr) );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");
  ptr+= nw;
  
  Serial.print( nw ); Serial.print(",");
  Serial.println( tstr );
  Serial.print( nr ); Serial.print(",");
  Serial.println( rstr ); 
  Serial.println();

// Test read/write of integers
  
  Serial.print("Writing integer @ 0x"); Serial.println( ptr, HEX );
  tod = millis();
  nw = ep.write( ptr, &it );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");

  Serial.println("Reading integer..");
  tod = millis();
  nr = ep.read( ptr, &ir );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");
  ptr+= nw;
  
  Serial.print( nw ); Serial.print(",");
  Serial.println( it, DEC );
  Serial.print( nr ); Serial.print(",");
  Serial.println( ir, DEC ); 
  Serial.println();

// Test read/write of unsigned integers
  
  Serial.print("Writing unsigned integer @ 0x"); Serial.println( ptr, HEX );
  tod = millis();
  nw = ep.write( ptr, &uit );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");

  Serial.println("Reading unsigned integer..");
  tod = millis();
  nr = ep.read( ptr, &uir );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");
  ptr+= nw;
  
  Serial.print( nw ); Serial.print(",");
  Serial.println( uit, DEC );
  Serial.print( nr ); Serial.print(",");
  Serial.println( uir, DEC ); 
  Serial.println();

// Test read/write of long integers
  
  Serial.print("Writing long integer @ 0x"); Serial.println( ptr, HEX );
  tod = millis();
  nw = ep.write( ptr, &lit );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");

  Serial.println("Reading long integer..");
  tod = millis();
  nr = ep.read( ptr, &lir );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");
  ptr+= nw;
  
  Serial.print( nw ); Serial.print(",");
  Serial.println( lit, DEC );
  Serial.print( nr ); Serial.print(",");
  Serial.println( lir, DEC ); 
  Serial.println();

// Test read/write of long unsigned integers
  
  Serial.print("Writing long unsigned integer @ 0x"); Serial.println( ptr, HEX );
  tod = millis();
  nw = ep.write( ptr, &ulit );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");

  Serial.println("Reading long unsigned integer..");
  tod = millis();
  nr = ep.read( ptr, &ulir );
  Serial.print( millis() - tod, DEC );
  Serial.println(" ms.");
  ptr+= nw;
  
  Serial.print( nw ); Serial.print(",");
  Serial.println( ulit, DEC );
  Serial.print( nr ); Serial.print(",");
  Serial.println( ulir, DEC ); 
  Serial.println();

}

void loop() {
}

