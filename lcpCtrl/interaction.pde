void mouseReleased() {

  //for (int i=0; i<vecs.size(); i++) {    
  //  printerX = vecs.get(i).x;
  //  printerY = vecs.get(i).y;
  //  if (i==0) {
  //    speed = 1500;
  //  } else {
  //    speed = 200;
  //  }
  //  myPort.write("G1 F" + speed + "\r\n");
  //  myPort.write("G1 X"+ printerX + " Y" + printerY + "\r\n");
  //  stroke(255);
  //  fill(255);
  //  println("curr row: "+ i);
  //}


  // set destination with mouse
  //PVector m = new PVector(mouseX, mouseY);
  //for (tile t : tiles) {
  //  float d = t.pos.dist(m);
  //  if (d < 5) {
  //    printerX = int((width-t.pos.x)/2); // need to reverse and scale mouse coords to reflect printer coords
  //    printerY = int(mouseY/2);
  //    //println(printerX, printerY);
  //    myPort.write("G1 F" + speed + "\r\n");
  //    myPort.write("G1 X"+ printerX + " Y" + printerY + "\r\n");
  //    t.c = color(255, 255, 255);
  //  }
  //}
}


void keyReleased() {

  // home x and y
  if (key == 'h') {
    myPort.write("G28 X"+"\r\n");
    myPort.write("G28 Y"+"\r\n");
  }

  // reset tiles
  if (key == 'r') {
    for (tile t : tiles) {
      t.c = color(0, 0, 0);
    }
  }

  // reset tiles
  if (key == 'f') {
    printerX = vecs.get(0).x;
    printerY = vecs.get(0).y;
    myPort.write("G1 X"+ printerX + " Y" + printerY + "\r\n");
  }

  // start printing
  if (key == 's') {
    start = true;
  }

  // speed control
  if (key == 't') { // default travel speed
    speed = 1500; 
    println("speed: " + speed);
  }
  if (key == 'b') { // default build speed
    speed = 100;
    println("speed: " + speed);
  }


  if (key == CODED) {
    if (keyCode == UP) {
      speed+=5; 
      println("speed: " + speed);
    }
    if (keyCode == DOWN) {
      speed-=5; 
      println("speed: " + speed);
    }
  }
}
