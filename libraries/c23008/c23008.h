//Generic library for MCP23008 port expander
// Ports library definitions
// 10-20-2010 <patf11@hotmail.com> http://opensource.org/licenses/mit-license.php

class c23008Expander {
public:
  void begin(uint8_t unit, uint8_t ports);
  void begin(uint8_t unit);
  void begin(void);

  void writeByte(uint8_t data);
  void setInputs(uint8_t ports);
  void setPullups(uint8_t ports);
  void setInverse(uint8_t ports);
  uint8_t readByte();

 private:
  uint8_t deviceAddress;
};

#define BASE_ADDRESS 0x20  //Base address of chip

// registers
#define IODIR 0x00
#define IPOL 0x01
#define GPINTEN 0x02
#define DEFVAL 0x03
#define INTCON 0x04
#define IOCON 0x05
#define GPPU 0x06
#define INTF 0x07
#define INTCAP 0x08
#define GPIO 0x09
#define OLAT 0x0A
