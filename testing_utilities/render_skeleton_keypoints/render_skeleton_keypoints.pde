import java.util.Map;
import oscP5.*;
import netP5.*;
import controlP5.*;

OscP5 oscP5;
NetAddress simulatorIAC;
ControlP5 cp5;

Controller oscInLabel, troubleshootingLabel, frameRateLabel;

// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateWidthHalf = buildPlateWidth/2;
int buildPlateHeight = 280;
int buildPlateHeightHalf = buildPlateHeight/2;

// ------ other ------
boolean flash = false;
String troubleshootingText = "If not receiving OSC: \n"
  + "1. is posenet tracker running? \n"
  + "2. is firebase-osc-relay running?";



// Note the HashMap's "key" is a String and "value" is an Integer
HashMap<String, PVector> keypoints = new HashMap<String, PVector>();


void setup() {
  size(600, 500);
  cp5 = new ControlP5(this);

  /* start oscP5, listening for incoming messages at port 10419 */
  oscP5 = new OscP5(this, 10419);

  /* simulatorIAC is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. simulatorIAC is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  simulatorIAC = new NetAddress("127.0.0.1", 10420);

  oscInLabel = cp5.addTextlabel("oscLabel")
    .setText("OSC input: [ ]")
    .setPosition(25, 1*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 20))
    ;

  troubleshootingLabel = cp5.addTextlabel("troubleshootingLabel")
    .setText(troubleshootingText)
    .setPosition(25, 3*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 15))
    ;

  frameRateLabel = cp5.addTextlabel("frameRateLabel")
    .setText("n/a")
    .setPosition(25, 5*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 15))
    ;
}


void draw() {
  frameRateLabel.setStringValue(round(frameRate) + " fps");
  fill(0, 0, 0, 255);
  noStroke();
  rect(0, 0, width, height);


  if (flash) {
    oscInLabel.setStringValue("OSC input: [*]");
    flash = false;
  } else {
    oscInLabel.setStringValue("OSC input: [ ]");
  }

  drawKeypoints();
}

void drawKeypoints() {
  for (PVector point : keypoints.values()) {
    if (point.z > 0.5) {
      float r = map(point.x, 0, 600, 64, 255);
      float g = map(point.y, 0, 500, 64, 255);
      float b = 100;

      //fill(random(128)+64, random(128)+64, random(128)+64);
      fill(r, g, b);

      ellipse(point.x, point.y, random(6)+13, random(6)+13);
    }
  }
}

void setTextTroubleshooting() {
  oscInLabel.setStringValue(troubleshootingText);
}

void keyReleased() {  
  if (key == ' ') noiseSeed((int) random(100000));
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.typetag().length() == 102 && theOscMessage.checkAddrPattern("/lcp/tracking/pose")) { // 17 arrays * 6 typetag chars per array
    flash = true; // post osc message received

    for (int i=0; i<101; i+=6) {
      String part = theOscMessage.get(i+1).stringValue();
      float score = theOscMessage.get(i+2).floatValue();
      float x = theOscMessage.get(i+3).floatValue();
      float y = theOscMessage.get(i+4).floatValue();
      keypoints.put(part, new PVector(x, y, score));
    }
  }
}
