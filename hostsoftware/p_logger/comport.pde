// quick and dirty COMM Port selector using only the built-in Processing.org libraries

String comport_list[];
int comport_mouse_over = -1;
int comport_mouse_select = -1;

void comport_menu()
{
  if (whichport >= 0) return;

  comport_list = Serial.list();
  int nports = comport_list.length;
  if (nports == 0) {
    error_msg = "No COMM ports found";
    return;
  }

  if (nports == 1) try {
    whichport = 0;
    comport = new Serial(this, comport_list[whichport], baudrate);
    comport.clear();
    comport.bufferUntil('\n');
    return;
  } catch (Exception e) {
    delay(200);
    error_msg = "Error: failed to open COMM port";
    whichport = -1;
    comport_mouse_over = -1;
    comport_mouse_select = -1;
    return;
  }

  comport_mouse_over = -1;

  fill(255,255,255);
  textFont(menuFont);
  float h = textAscent() + textDescent() ;
  float y = h;
  float menu_w = textWidth("Choose COMM port") + 40.;
  float xorg=width/2 - menu_w/2;
  float yorg=height/4;
  rect(xorg,yorg, menu_w, height/2);

  pushMatrix();
  translate(xorg,yorg);
  
  fill(255,0,0);
  text("Choose COMM port", 20., y);
  y += 2*h;
  for (int i=0; i<nports; i++) {
    float mx = mouseX - xorg;
    float my = mouseY - yorg;
    if ( (mx > 0.) && (mx < menu_w ) && (my >= y-h) && (my <= y) ){
      fill(50,50,50);
      comport_mouse_over = i;
    } else {
      fill(255,255,255);
    }
    rect(0, y-h, menu_w, h);
    fill(255,0,0);
    text(comport_list[i], 20., y);
    line(0,y, menu_w,y);
    y += h;
   }
  
  if (comport_mouse_select < 0) {
    popMatrix();
    return;
  }

  //println("gonna try a com port");
  whichport = comport_mouse_select;
  
  try {
    comport = new Serial(this, comport_list[whichport], baudrate);
    comport.clear();
    comport.bufferUntil('\n');
    println("COMM port OK");
  } catch (Exception e) {
    error_msg = "Error: failed to open COMM port";
    whichport = -1;
    comport_mouse_over = -1;
    comport_mouse_select = -1;
  }
  popMatrix();
}

void comport_mousePressed()
{
  if (comport_mouse_over >= 0) {
    comport_mouse_select = comport_mouse_over;
//  println("mouse pressed: " + comport_mouse_select);
  }
}

