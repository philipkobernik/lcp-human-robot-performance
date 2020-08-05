import java.util.Map;
import oscP5.*;
import netP5.*;
import controlP5.*;

OscP5 oscP5;
NetAddress simulatorIAC;
ControlP5 cp5;

Controller oscInLabel, oscOutLabel, troubleshootingLabel;

// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateWidthHalf = buildPlateWidth/2;
int buildPlateHeight = 280;
int buildPlateHeightHalf = buildPlateHeight/2;

// ------ other ------
boolean inFlash, outFlash = false;
String troubleshootingText = "If not receiving OSC: \n"
  + "1. is posenet tracker running? \n"
  + "2. is firebase-osc-relay running?";

// Note the HashMap's "key" is a String and "value" is an Integer
HashMap<String, PVector> keypoints = new HashMap<String, PVector>();


void setup() {
  size(400, 400);
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

  oscInLabel = cp5.addTextlabel("oscInLabel")
    .setText("OSC input: [ ]")
    .setPosition(25, 1*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 20))
    ;

  oscOutLabel = cp5.addTextlabel("oscOutLabel")
    .setText("OSC output: [ ]")
    .setPosition(25, 2*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 20))
    ;

  troubleshootingLabel = cp5.addTextlabel("troubleshootingLabel")
    .setText(troubleshootingText)
    .setPosition(25, 4*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 15))
    ;
}


void draw() {
  fill(0, 0, 0, 255);
  noStroke();
  rect(0, 0, width, height);


  if (inFlash) {
    oscInLabel.setStringValue("OSC input: [*]");
    inFlash = false;
  } else {
    oscInLabel.setStringValue("OSC input: [ ]");
  }
  
  if (outFlash) {
    oscOutLabel.setStringValue("OSC output: [*]");
    outFlash = false;
  } else {
    oscOutLabel.setStringValue("OSC output: [ ]");
  }
  
  
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {

  if (theOscMessage.checkTypetag("fff")) { // if osc message has 3 floats

    String[] parts = theOscMessage.addrPattern().split("/");
    if (parts.length < 4) return; // if address pattern doesn't look right-- early return

    if (parts[1].equals("lcp") && parts[2].equals("tracking")) {
      inFlash = true;

      // looks like we're dealing with the right message-- store the part coords and score
      String part = parts[3]; // "nose" or "rightAnkle"
      float x = theOscMessage.get(0).floatValue();
      float y = theOscMessage.get(1).floatValue();
      float score = theOscMessage.get(2).floatValue();
      keypoints.put(part, new PVector(x, y));

      // now send some OSC messages to the LCP
      if (part.equals("nose")) messagePrinter(x, y, score);
    }
  }
}

void messagePrinter(float x, float y, float score) {
  outFlash = true;
  float xOut = map(x, 0, 600, 0, buildPlateWidth-1);
  float yOut = map(y, 0, 500, 0, buildPlateHeight-1);

  OscMessage position = new OscMessage("/lcp/control/position");

  position.add(xOut);
  position.add(yOut);
  position.add(105.0);
  oscP5.send(position, simulatorIAC); 

  OscMessage flow = new OscMessage("/lcp/control/flow");
  if (score > 0.65) {
    flow.add(map(score, 0.65, 1.0, 0.2, 1.0));
  } else {
    flow.add(0.0);
  }
  oscP5.send(flow, simulatorIAC);
}
