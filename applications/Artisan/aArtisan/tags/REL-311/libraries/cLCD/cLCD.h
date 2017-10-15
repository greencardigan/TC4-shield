// cLCD library
// For use with Jim Gallt's LCD adapter
// Copyright (C) 2010 MLG Properties, LLC (BSD license)

// derived from LiquidCrystal library (arduino-0018, public domain)
// derived from PortsLCD library (JeeLabs, MIT license)

// Revision history:
//   20120126: Arduino 1.0 compatibility
//     (thanks and acknowledgement to Arnaud Kodeck for his code contributions).

#ifndef cLCD_h
#define cLCD_h

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

#include <inttypes.h>
#include <Print.h>
#include "MCP23017.h"

// commands
#define LCD_CLEARDISPLAY 0x01
#define LCD_RETURNHOME 0x02
#define LCD_ENTRYMODESET 0x04
#define LCD_DISPLAYCONTROL 0x08
#define LCD_CURSORSHIFT 0x10
#define LCD_FUNCTIONSET 0x20
#define LCD_SETCGRAMADDR 0x40
#define LCD_SETDDRAMADDR 0x80

// flags for display entry mode
#define LCD_ENTRYRIGHT 0x00
#define LCD_ENTRYLEFT 0x02
#define LCD_ENTRYSHIFTINCREMENT 0x01
#define LCD_ENTRYSHIFTDECREMENT 0x00

// flags for display on/off control
#define LCD_DISPLAYON 0x04
#define LCD_DISPLAYOFF 0x00
#define LCD_CURSORON 0x02
#define LCD_CURSOROFF 0x00
#define LCD_BLINKON 0x01
#define LCD_BLINKOFF 0x00

// flags for display/cursor shift
#define LCD_DISPLAYMOVE 0x08
#define LCD_CURSORMOVE 0x00
#define LCD_MOVERIGHT 0x04
#define LCD_MOVELEFT 0x00

// flags for function set
#define LCD_8BITMODE 0x10
#define LCD_4BITMODE 0x00
#define LCD_2LINE 0x08
#define LCD_1LINE 0x00
#define LCD_5x10DOTS 0x04
#define LCD_5x8DOTS 0x00

// base class for LCD objects
class LCDbase : public Print {
public:
	LCDbase(){};
	void begin(uint8_t cols, uint8_t rows, uint8_t charsize = LCD_5x8DOTS );
	void clear();
	void home();
	void noDisplay();
	void display();
	void noBlink();
	void blink();
	void noCursor();
	void cursor();
	void scrollDisplayLeft();
	void scrollDisplayRight();
	void leftToRight();
	void rightToLeft();
	void autoscroll();
	void noAutoscroll();

	void createChar(uint8_t, uint8_t[]);
	void setCursor(uint8_t, uint8_t);

#if defined(ARDUINO) && ARDUINO >= 100
  virtual size_t write(uint8_t);
#else
  virtual void write(uint8_t);
#endif

	void command(uint8_t);
      virtual void backlight(){}
      virtual void noBacklight(){}

protected:
	virtual void config() = 0;
	virtual void send(uint8_t, uint8_t) = 0;
	virtual void write4bits(uint8_t) = 0;
	uint8_t _displayfunction;
	uint8_t _displaycontrol;
	uint8_t _displaymode;
	uint8_t _initialized;
	uint8_t _numlines,_currline;
};

// standard LiquidCrystal class, but derived from base class instead
class LiquidCrystal : public LCDbase {
public:
  LiquidCrystal(uint8_t rs, uint8_t enable,
		uint8_t d0, uint8_t d1, uint8_t d2, uint8_t d3,
		uint8_t d4, uint8_t d5, uint8_t d6, uint8_t d7);
  LiquidCrystal(uint8_t rs, uint8_t rw, uint8_t enable,
		uint8_t d0, uint8_t d1, uint8_t d2, uint8_t d3,
		uint8_t d4, uint8_t d5, uint8_t d6, uint8_t d7);
  LiquidCrystal(uint8_t rs, uint8_t rw, uint8_t enable,
		uint8_t d0, uint8_t d1, uint8_t d2, uint8_t d3);
  LiquidCrystal(uint8_t rs, uint8_t enable,
		uint8_t d0, uint8_t d1, uint8_t d2, uint8_t d3);
  // init is called by constructors
  void init(uint8_t fourbitmode, uint8_t rs, uint8_t rw, uint8_t enable,
	    uint8_t d0, uint8_t d1, uint8_t d2, uint8_t d3,
	    uint8_t d4, uint8_t d5, uint8_t d6, uint8_t d7);
protected:
  virtual void config();
  virtual void send( uint8_t, uint8_t );
  virtual void write4bits( uint8_t );

  void write8bits(uint8_t);
  void pulseEnable();
private:
  uint8_t _rs_pin; // LOW: command.  HIGH: character.
  uint8_t _rw_pin; // LOW: write to LCD.  HIGH: read from LCD.
  uint8_t _enable_pin; // activated by a HIGH pulse.
  uint8_t _data_pins[8];
};

// class for LCD connected to MCP23017 port expander on adapter
class cLCD : public LCDbase {
public:
	cLCD( uint8_t addr = MCP23_ADDR );
	virtual void backlight();
	virtual void noBacklight();
protected:
	virtual void config();
	virtual void send( uint8_t, uint8_t );
	virtual void write4bits( uint8_t );
private:
	uint8_t PEaddr; // I2C address of the port expander
	uint8_t bklight;
};

#endif
