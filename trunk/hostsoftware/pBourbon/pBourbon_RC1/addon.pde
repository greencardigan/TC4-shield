//added 10-15  pf
int msgflag = 0;   //flag for keypress
//messages sent to csv by key press
String message[]= {
  "", "Load Beans", "First Crack", "Second Crack","End Roast"
};
//char sent to graph by key press
char key_event[] = {
  '1','L','F','S','E'
};
char[] key_hist = new char[10];
float[] key_pos = new float[10];
char[] msg_hist = new char[10];
float[] msg_pos = new float[10];
int key_count = 0;
int msg_count = 0;
float x_pos;  //Track chart x position
float endTimer = -1; 
int endTimerSeconds = 30;//Seconds to end program after end of roast message
color blue = color(10,10,255);  //color for message key

//Modified Key press to capure location on graph when key pressed
void keyPressed()
{ 
  if( !started ) { 
    started = true;
  }
  else {
    switch( key )
    {
    case 'f' :
    case 'F' :
      {
        msgflag = 2;
      }
      break;

    case 'S' :
    case 's' :
      {
        msgflag = 3;
      }
      break;

    case 'm' :
    case 'M' :
      frame.setLocation(500, 5); 
      break;

    case 'e' :
    case 'E' :
      msgflag = 4;
      break;

    case 'l' :    //Load beans and restart timer
    case 'L' :
      //      comport.stop();
      //      startSerial();
      msgflag = 1;
      //      key_count = 0; // reset graph markers
      break;
    };
  }
  if (msgflag > 0) {
    key_count++;
    key_hist[key_count] = key_event[msgflag];
    key_pos[key_count] = x_pos;
  }
}

//changed 10-13 PF
void drawnote() {

  if (kb_note.length() > 0) {
    textFont(labelFont);
    stroke(128,128,128);
    text(kb_note, 100, 100);
  }

  //10-15 added to show when F,S,L,E keys pressed
  if (key_count > 0) {
    textFont(labelFont);
    stroke(128,128,128);
    for (int i = 1; i <= key_count; i++) {
      text(key_hist[i], key_pos[i], 80);
    }
  }
  if (msg_count > 0) {
    fill(blue);
    for (int i = 1; i <= msg_count; i++) {
      text(msg_hist[i], msg_pos[i], 95);
    }
  }
}

void msgRecevided(char msg )
{ 


//  print("processing msg= ");
//  println(msg);

  switch( msg )
  {
  case 'f' :
  case 'F' :
    {
      msgflag = 2;
    }
    break;

  case 'S' :
  case 's' :
    {
      msgflag = 3;
    }
    break;

  case 'e' :
  case 'E' :
    msgflag = 4;
    endTimer = timestamp;
    print("Setting endTimer");
    break;

  case 'l' :    //Load beans and restart timer
  case 'L' :
    //       comport.stop();
    //       startSerial();
    msgflag = 1;
    break;
  };

//  print("message flag= ");
//  println(msg);

  if (msgflag > 0) {
    msg_count++;
    msg_hist[msg_count] = key_event[msgflag];
    msg_pos[msg_count] = x_pos;
  }
}

