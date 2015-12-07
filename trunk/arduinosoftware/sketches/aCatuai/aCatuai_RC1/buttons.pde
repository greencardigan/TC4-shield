
#ifdef ANALOG_IN
// ---------------------------------
void readPot() { // read analog port 1, round to nearest 5% output value
  char pstr[5];
  int32_t mod, trial;
  aval = analogRead( anlg );
  lcd.setCursor( 0, 2 );
  lcd.print( "read " ); 
  lcd.print(aval);

  trial = aval * 100;
  lcd.print( " t1 " ); 
  lcd.print(trial);
  trial /= 1023;
  mod = trial % 5;
  lcd.setCursor( 0, 3 );
  lcd.print( "t2 " ); 
  lcd.print(trial);
  lcd.print( " mod " ); 
  lcd.print(mod);
  trial = ( trial / 5 ) * 5; // truncate to multiple of 5
  if( mod >= 3 )
    trial += 5;
  if( trial <= 100 && trial != power ) { // did it change?
    power = trial;
    sprintf( pstr, "%3d", (int)power );
    lcd.setCursor( 6, 0 );
    lcd.print( pstr ); 
    lcd.print("%");
  }
}
#endif

#ifdef c23008
  void p_button() { // read buttons and adjust power and speed
  char pstr[5];
  int trial, fanTrial;
  String keyMessage;

#define UP    1
#define DOWN 16
#define LEFT  2
#define RIGHT 4
#define ENTER 8
#define MINUS 32
#define PLUS 128
#define PLUSMINUS 160  //both keys depressed

  trial = power; 
  fanTrial =fanSpeed;

  byte button =  expander.readByte();
  //  byte button =  expander.readButtons();

  if(button > 0){
    if(OldButton != button){  //Check if button held down

        switch (button) {
      case ENTER :
        keyMessage = "Not Yet";
        if( (timestamp - lastEventTime) > EVENT_DELAY){  // since last event
          lastEventTime = timestamp; 
          if( key_count == 0){  //load beans
            trial = LOADPOWER;        //start heater at 
            fanTrial = LOADSPEED;
            //          resetTimer();
            //          timestamp = 30;
          }

          if(key_count < Key_Count_Size){
            key_count++;
            //Send event to serial port
            Serial.print("%%%");
            Serial.println(key_event[key_count]);
          } 
          if (key_count == Key_Count_Size){
            trial = 0;
            fanTrial = ENDSPEED;
          }
//          time1 = millis(); 
//          timestamp2 = 0;
//          timeReset = time1;
          keyMessage = "Event +";
        }

        break; 

      case PLUSMINUS :  //abort roast if both buttons pressed
        key_count = Key_Count_Size;
        trial = 0;
        fanTrial = ENDSPEED;
        //Send event to serial port
        Serial.print("%%%");
        Serial.println(key_event[key_count]);
        keyMessage = "PLUSMINUS";
        break;  

      case UP :  
        if(trial < 100){
          trial = trial + 5;
        }
        keyMessage = "Power +";
        break;


      case DOWN:  //DOWN
        if (trial > 0){
          trial = trial - 5;
        }
        keyMessage = "Power -";
        break;

      case PLUS :  
        if(fanTrial < 100){
          fanTrial = fanTrial + 5;
        }
        keyMessage = "Fan +";
        break; 
      case MINUS :  
        if(fanTrial > 0){
          fanTrial = fanTrial - 5;
        }
        keyMessage = "Fan -";
        break;   

      case LEFT :  
      case RIGHT :  
        time1 = millis(); 
        timestamp2 = 0;
        keyMessage = "Reset";
        break; 
      }
      lcd.setCursor( 8, 3 );
      lcd.print(message[key_count] );
      lcd.print("    "); 
      lcd.setCursor( 11, 2 );
      lcd.print(keyMessage);
      lcd.print("    ");  
    } 
    else {
      if( (timestamp - lastEventTime) > EVENT_DELAY){
        if (OldButton == ENTER){
          lcd.setCursor( 8, 3 );
          lcd.print("Reset in ");
          lcd.print((EVENT_DELAY *4)- (timestamp - lastEventTime), 0);
          lcd.print("  ");
          if( ((timestamp - lastEventTime)) > (EVENT_DELAY *4)){
            resetFunc();
          }
        }
      } 
      else{     
        lcd.setCursor( 8, 3 );
        lcd.print(message[key_count] );
        lcd.print("    "); 
      }
    }
  }
  OldButton = button;

  if( trial <= 100 && trial != power ) { // did it change?
    power = trial;
#ifdef LCD_20_4 
    sprintf( pstr, "%3d", (int)power );
    lcd.setCursor( 6, 0 );
    lcd.print( pstr ); 
    lcd.print("%");
#endif    

  }

#ifdef FANCONTROL
  if( fanTrial <= 100 && fanTrial != fanSpeed ) { // did it change?
    fanSpeed = fanTrial;
#ifdef LCD_20_4 
    sprintf( pstr, "%3d", (int)fanSpeed );
    lcd.setCursor( 6, 2 );
    lcd.print( pstr ); 
    lcd.print("%");
#endif    
  }
#endif  
}
#endif


#ifdef I2C_LCD
// ----------------------------------
void checkButtons() { // take action if a button is pressed
  if( buttons.readButtons() ) {
    if( buttons.keyPressed( 3 ) && buttons.keyChanged( 3 ) ) {// left button = start the roast
      resetTimer();
      Serial.println( "# STRT (timer reset)");
    }
    else if( buttons.keyPressed( 2 ) && buttons.keyChanged( 2 ) ) { // 2nd button marks first crack
      resetTimer();
      Serial.println( "# FC (timer reset)");
    }
    else if( buttons.keyPressed( 1 ) && buttons.keyChanged( 1 ) ) { // 3rd button marks second crack
      resetTimer();
      Serial.println( "# SC (timer reset)");
    }
    else if( buttons.keyPressed( 0 ) && buttons.keyChanged( 0 ) ) { // 4th button marks eject
      resetTimer();
      Serial.println( "# EJCT (timer reset)");
    }
  }
}
#endif

#ifndef c23008
// ------------------------------------------------------------------------
//this routine sees if a button was pushed, returns the button value

int get_button (void){

  int button_pushed;
  boolean pushed;

  button_pushed = NOBUTTON;

  if (digitalRead (PLUSPIN) == 1) {  //see if the Plus button was pushed
    button_pushed = PLUS;
  }
  if (digitalRead (MINUSPIN) == 1) {  //see if the Minus button was pushed
    button_pushed = MINUS;
  }
  return button_pushed;  
}
#endif
