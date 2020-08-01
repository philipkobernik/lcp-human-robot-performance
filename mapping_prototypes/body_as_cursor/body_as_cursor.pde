/**
 * oscP5sendreceive by andreas schlegel
 * example shows how to send and receive osc messages.
 * oscP5 website at http://www.sojamo.de/oscP5
 */

import oscP5.*;
import netP5.*;
import controlP5.*;

OscP5 oscP5;
NetAddress simulatorIAC;
ControlP5 cp5;

Controller oscInLabel;

// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateWidthHalf = buildPlateWidth/2;
int buildPlateHeight = 280;
int buildPlateHeightHalf = buildPlateHeight/2;

// ------ other ------
boolean flash = false;


void setup() {
  size(400, 400);
  frameRate(25);
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
    .setText("n/a")
    .setPosition(25, 1*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 25))
    ;
}


void draw() {
  fill(0, 0, 0, 128);
  rect(10, 10, width-20, height-20);
  
  
  if(flash) {
    oscInLabel.setStringValue("<--> receiving OSC");
    flash = false;
  } else {
  }
}

void keyReleased() {  
  if (key == ' ') noiseSeed((int) random(100000));
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/lcp/tracking/nose")) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("fff")) {
      flash = true;
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float x = theOscMessage.get(0).floatValue();  
      float y = theOscMessage.get(1).floatValue();
      float score = theOscMessage.get(2).floatValue();
      
      float xOut = map(x, 0, 600, 0, buildPlateWidth-1);
      float yOut = map(y, 0, 500, 0, buildPlateHeight-1);
      
      OscMessage position = new OscMessage("/lcp/control/position");

      position.add(xOut);
      position.add(yOut);
      position.add(105.0);
      oscP5.send(position, simulatorIAC); 
      
      OscMessage flow = new OscMessage("/lcp/control/flow");
      if(score > 0.65) {
        flow.add(map(score, 0.65, 1.0, 0.2, 1.0));
      } else {
        flow.add(0.0);
      }
      oscP5.send(flow, simulatorIAC);

      return;
    }
  }
}
