// timer1defs.h

#ifndef _timer1defs_h
#define _timer1defs_h

// timer 1 setup constants
#define TIMSK1_ICIE1 5 // input capture interrupt enable
#define TIMSK1_OCIE1B 2 // output compare B match interrupt enable
#define TIMSK1_OCIE1A 1 // output compare A match interrupt enable
#define TIMSK1_TOIE1 0 // overflow interrupt enable
#define TCCR1A_COM1A1 7 // compare output mode for channel A (high bit)
#define TCCR1A_COM1A0 6 // compare output mode for channel A (low bit)
#define TCCR1A_COM1B1 5 // compare output mode for channel B (high bit)
#define TCCR1A_COM1B0 4 // compare output mode for channel B (low bit)
#define TCCR1A_WGM1 1   // waveform generation mode (high bit)
#define TCCR1A_WGM0 0   // waveform generation mode (low bit)
#define TCCR1B_ICNC1 7  // input capture noise canceler enable
#define TCCR1B_ICES1 6  // input capture edge select
#define TCCR1B_WGM13 4  // waveform generation mode
#define TCCR1B_WGM12 3  // waveform generation mode
#define TCCR1B_CS12  2  // clock select
#define TCCR1B_CS11  1  // clock select
#define TCCR1B_CS10  0  // clock select
#define TCCR1C_FOC1A 7 // force output compare channel A
#define TCCR1C_FOC1B 6 // force output compare channel B

#endif
