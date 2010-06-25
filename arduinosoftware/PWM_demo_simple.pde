#include <PWM16.h>

unsigned int T = pwmN4Hz;
unsigned int duty = 30;
PWM16 pwmOut;

void setup() {
  pwmOut.Setup( T );
  pwmOut.Out ( duty, 0 );
}

void loop() {}


