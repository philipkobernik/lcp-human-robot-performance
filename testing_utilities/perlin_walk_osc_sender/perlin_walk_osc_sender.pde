/**
 * oscP5sendreceive by andreas schlegel
 * example shows how to send and receive osc messages.
 * oscP5 website at http://www.sojamo.de/oscP5
 */
 
import oscP5.*;
import netP5.*;
  
OscP5 oscP5;
NetAddress simulatorIAC;

// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateWidthHalf = buildPlateWidth/2;
int buildPlateHeight = 280;
int buildPlateHeightHalf = buildPlateHeight/2;

// ------ perlin walk ------
boolean walkActive = true;
PVector p;
PVector pOld;
float stepSize = 0.25;
float noiseScale = 100; 
float noiseStrength = 20;
float noiseZ, noiseZVelocity = 0.01;
float angle;

void setup() {
  size(400,400);
  frameRate(25);
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,10421);
  
  /* simulatorIAC is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. simulatorIAC is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  simulatorIAC = new NetAddress("127.0.0.1",10420);
  
  p = new PVector(buildPlateWidthHalf, buildPlateHeightHalf);
  pOld = p.copy();
}


void draw() {
  if (walkActive) {
    angle = noise(p.x/noiseScale, p.y/noiseScale, noiseZ) * noiseStrength;
    p.x += cos(angle) * stepSize;
    p.y += sin(angle) * stepSize;

    // offscreen wrap
    if (p.x<20) p.x=pOld.x=340-30;
    if (p.x>340-20) p.x=pOld.x=30;
    if (p.y<20) p.y=pOld.y=280-30;
    if (p.y>280-20) p.y=pOld.y=30;
    
    pOld.set(p);
    noiseZ += noiseZVelocity*2;
    
    OscMessage position = new OscMessage("/lcp/control/position");

    position.add(p.x);
    position.add(p.y);
    position.add(105.0);
    oscP5.send(position, simulatorIAC); 
    
    OscMessage flow = new OscMessage("/lcp/control/flow");
    flow.add(2.5);
    oscP5.send(flow, simulatorIAC);

    background(128);
  } else {
    background(0);
  }
}

void keyReleased() {  
  if (key == 'w' || key == 'W') walkActive = !walkActive;
  if (key == ' ') noiseSeed((int) random(100000));
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}
