ImageButtons gifbutton;

void printProfiles() {  //list out guide profiles
  // int thisEntry = 0; 
  fill (white);
  textFont(selectFont);
  text ("Select guide profile", 10, 20);

//  println("RecordCount= "+recordCount +"  MAXPROFILEPAGE= "+MAXPROFILEPAGE);
//  println("first base=" + baseProfile + "  itemSelected=" +  itemSelected);

  if(itemSelected < 0) {
    itemSelected = 0;
  }

  if(itemSelected < baseProfile ) {
    baseProfile--;
  }

  if(itemSelected > (recordCount -1)) {
    itemSelected = recordCount-1;
  }
  if(itemSelected >= (baseProfile + MAXPROFILEPAGE)) {
    baseProfile++;
  }
  
  if(baseProfile < 0) {
    baseProfile = 0;
  }
  
  if(baseProfile > recordCount) {
    baseProfile = recordCount -  MAXPROFILEPAGE;
  }
  if(itemSelected >= (baseProfile + MAXPROFILEPAGE)){
    itemSelected = baseProfile + MAXPROFILEPAGE - 1;
  }
    if(itemSelected < baseProfile ){
    itemSelected = baseProfile;
  }

  //println("second base=" + baseProfile + "  itemSelected=" +  itemSelected);
  textFont( labelFont );
  fill (green);
  text ("Profiles " + nf(baseProfile,0) + " to " + nf(baseProfile + MAXPROFILEPAGE -1,2) + " of " + nf(recordCount -1,2), 25, 40);
  textFont(selectFont);
  fill (white);
  for( int i = baseProfile; i < (baseProfile + MAXPROFILEPAGE) ; i++) {
    if (i > (recordCount - 1)) {
      return;
    }
    gifbutton.update();
    gifbutton.display();  

    if (i == itemSelected) {
      fill(blue);
    }
    else {
      fill(white);
    }
    text((i ) + " > " + (String)fileNames.get(i), 20, 20 + ((i - baseProfile) * 25)+45);
  }
}


class gifButton
{
  int x, y;
  int w, h;
  color basecolor, highlightcolor;
  color currentcolor;
  boolean over = false;
  boolean pressed = false;   

  void pressed() {
    if(over && mousePressed) {
      pressed = true;
    } 
    else {
      pressed = false;
    }
  }

  boolean overRect(int x, int y, int width, int height) {
    if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
      return true;
    } 
    else {
      return false;
    }
  }
}

class ImageButtons extends gifButton 
{
  PImage base;
  PImage roll;
  PImage down;
  PImage currentimage;

  ImageButtons(int ix, int iy, int iw, int ih, PImage ibase, PImage iroll, PImage idown) 
  {
    x = ix;
    y = iy;
    w = iw;
    h = ih;
    base = ibase;
    roll = iroll;
    down = idown;
    currentimage = base;
  }

  void update() 
  {
    over();
    pressed();
    if(pressed) {
      //     println("Pressed");
      //     println("x=" + mouseX +"  Y=" + mouseY);
      currentimage = down;
    } 
    else if (over) {
      currentimage = roll;
      //            println("Roll");
      //      println("x=" + mouseX +"  Y=" + mouseY);
    } 
    else {
      currentimage = base;
      //            println("Base");
      //      println("x=" + mouseX +"  Y=" + mouseY);
    }
  }

  void over() 
  {
    //    println("x=" + x + " y=" + y + " w=" +w +" h ="+h);
    if( overRect(x, y + 110 + currentimage.height, w, h) ) {
      //     println("Over = true");
      over = true;
    } 
    else {
      over = false;
      //     println("Over = false");
    }
  }

  void display() 
  {
    image(currentimage, x, y);
  }
}

