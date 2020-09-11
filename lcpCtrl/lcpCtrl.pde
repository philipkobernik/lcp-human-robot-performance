import processing.serial.*;
import processing.opengl.*;
import java.util.Calendar;
import controlP5.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
boolean oscInputActive = true;

ControlP5 cp5;

Serial myPort;
int cmdCount = 0;

ArrayList<tile> tiles = new ArrayList<tile>();
float printerX, printerY;
int speed = 100; // mm/sec

String sheetName = "centroids2.csv";
Table centroids;
int rowCount;
int row = 1;
boolean start = false;
ArrayList<PVector> vecs = new ArrayList<PVector>();

void setup() {
  //size(730, 930); // printer dimensions: x: 365 y: 465 (window scaled by 2 for interface purposes 
  size(400, 200);

  cp5 = new ControlP5(this);
  oscP5 = new OscP5(this, 10420);

  // initialize tiles
  //for (int i=5; i<730; i+=10) {
  //  for (int j=5; j<height; j+=10) {
  //    tiles.add(new tile(i, j));
  //  }
  //}

  loadData();  

  // initialize serial connection
  printArray(Serial.list());
  myPort = new Serial(this, Serial.list()[1], 115200);
  myPort.write("start");
  println(myPort.read());
}


void draw() {
  background(240, 170, 153);

  if (start) {
    if (oscInputActive) {
      //if (frameCount % 2 == 0) {
        //for (int i=0; i<vecs.size(); i++) {    
        //printerX = vecs.get(row).x;
        //printerY = vecs.get(row).y;
        //if (row==0) {
        //  speed = 1500;
        //} else {
        //  speed = 200;
        //}
        myPort.write("G1 F" + speed + "\r\n");
        myPort.write("G1 X"+ printerX + " Y" + printerY + "\r\n");
        stroke(255);
        fill(255);
        //println("curr row: "+ row);
        //row++;
        //}
      //}
    }
  }
  //for (tile t : tiles) {
  //  t.render();
  //}
}


void oscEvent(OscMessage theOscMessage) {
  if (!oscInputActive) return;

  if (theOscMessage.checkAddrPattern("/lcp/control/position")) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("fff")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float xIn = theOscMessage.get(0).floatValue();
      float yIn = theOscMessage.get(1).floatValue();
      float zIn = theOscMessage.get(2).floatValue();

      printerX = xIn;
      printerY = yIn;
      return;
    }
  }

  if (theOscMessage.checkAddrPattern("/lcp/control/flow")) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("f")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float flow = theOscMessage.get(0).floatValue();  

      //flowNormalizedSlider.setValue(flow);      
      return;
    }
  }

  return;
}
