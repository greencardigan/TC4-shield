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
int UP = 38;
int DOWN = 40;

void buildTitle() { 
  if (profile_data == null) {
    frame.setTitle(appname + "   Guide Profile = " + PROFILE);
  }
  else { 
    String[] rec = split(profile_data[0], ',');
    frame.setTitle(appname + "   Guide Profile = " + PROFILE + "  Time= " + nf(int(rec[0])/60,2) + ":" + nf(int(rec[0])%60,2) + "  End Temp= " + rec[1]);
  }
}  

//Modified Key press to capure location on graph when key pressed
void keyPressed()
{ 
  if( !started ) { 
    if( enable_guideprofile == false) {
      started = true;
    }
    else { 
      if (key == CODED) {
        if (keyCode == UP) {
          if (itemSelected > 0) {
            itemSelected--;
          }
        } 
        else if (keyCode == DOWN) {
          if (itemSelected < recordCount -1) {
            itemSelected++;
          }
        }
        else if (keyCode == KeyEvent.VK_PAGE_DOWN) { //Page Down
          baseProfile += MAXPROFILEPAGE;
          if(baseProfile + MAXPROFILEPAGE > recordCount ) {
            baseProfile = recordCount - MAXPROFILEPAGE;
          }
          itemSelected =  baseProfile;
        }
        else if (keyCode ==KeyEvent.VK_PAGE_UP) { //Page Up
          baseProfile -= MAXPROFILEPAGE;
          itemSelected =  baseProfile;
        }
        else if (keyCode ==KeyEvent.VK_HOME) { //Page Up
          baseProfile = 0;
          itemSelected =  baseProfile;
        }
        else if (keyCode == KeyEvent.VK_END) { //Page Down
          baseProfile = recordCount - MAXPROFILEPAGE;
          itemSelected =  baseProfile;
        }
        //      redraw();
      } 
      int keyIndex = -1;
      if (key >= '0' && key <= '9') {
        keyIndex = key - '0';
        if ((keyIndex < recordCount)) {
          itemSelected = keyIndex;
          redraw();
        }
      }
      else {
        if(( key == ENTER) || (key == RETURN)) {
          startProfile();
        }
      }
      redraw();
    }
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

void mouseMoved() {
  if( !started ) { 
    gifbutton.update();
    gifbutton.display();
    redraw();
  }
}
// ------------------------------- save a frame when mouse is clicked
void mouseClicked() {
  if( !started ) { 
    if( enable_guideprofile == true) {
      //    started = true;
      //   frame.setLocation(500, 5);
      gifbutton.update();
      gifbutton.display();
      if(gifbutton.over == true) {
        gifbutton.display();
        startProfile();
        //        println("mouse next");
      }
      else {

        int base = 80;

        if (mouseY > 200) {
          base =97;
        }
        if (mouseY > 330) {
          base =108;
        }
        if (mouseY > 400) {
          base =120;
        }
        if (mouseY > 450) {
          base =139;
        }
        int y =((mouseY -base) /30) +baseProfile;
        //println("mouse= "+mouseY+ "  base= "+ base +" y= " + y);
        if(y < (int)recordCount) {
          itemSelected = y;
          //println("itemSelected= "+itemSelected +"  recordCount= "+recordCount);
        }
        redraw();
        if (mouseEvent.getClickCount()==2) {
          println("<double click>");
          startProfile();
        }
      }
    }
    else {
      started = true;
      frameRate(1);
      startSerial();
      loop();
    }
  } 
  else {
    frame.setLocation(500, 5); 
    if (useAddon == false) {
      saveFrame(filename + "-##" + ".jpg" );
    }
  }
}

void startProfile() {
  started = true;
  redraw();
  frameRate(1);
  loop();
  // PROFILE =(String)fileNames[itemSelected];
  PROFILE =(String)fileNames.get(itemSelected);
  if(itemSelected > 0) {        
    profile_data = loadStrings(PROFILE +".csv");        
    println(PROFILE);
  }
  buildTitle();
  startSerial();
}

void mouseWheel(int delta) { 
  itemSelected += delta; 
  redraw();
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

// this is the filter (returns true if file's extension is .csv)
FilenameFilter csvFilter = new FilenameFilter() {
  boolean accept(File dir, String name) {
    //   return name.toLowerCase().endsWith(".csv");
    return name.endsWith(".csv");
  }
};

void dirListing() {  //gets all files in sketch directory with .csv
  File folder = new File(sketchPath);
  fileNames = new ArrayList();  
  String[] names = folder.list(csvFilter);
  fileNames.add(new String("None"));
  for (int i = 0; i < names.length; i++) {
    fileNames.add (new String(split(names[i], '.')[0]));
  }
  recordCount = fileNames.size();
}


