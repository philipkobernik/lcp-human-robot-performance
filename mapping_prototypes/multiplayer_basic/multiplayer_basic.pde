import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.*;

OscP5 oscP5;
NetAddress simulatorIAC;
ControlP5 cp5;

Controller oscInLabel, oscOutLabel, positionSmoothingSlider, troubleshootingLabel, textInput, radioButton;

Trace trace;


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
HashMap<String, PVector> positions = new HashMap<String, PVector>();

HashMap<String, HashMap<String, PVector>> group = new HashMap<String, HashMap<String, PVector>>();

HashMap<String, PVector> velocities = new HashMap<String, PVector>();

// smoothing
float positionSmoothing = 0.25;

// participatory option
int participatoryMode = 0;
PVector nozzlePosition;
// mode 0
HashMap<String, PVector> centroids = new HashMap<String, PVector>();
PVector generalCentroid = new PVector(0, 0);
// mode 1
int trackedId = 0;

void setup() {
  size(1200, 1000, P3D);
  frameRate(60);
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

  // we position the printer nozzle in the middle of the canvas first
  nozzlePosition =  new PVector(width/2, height/2);
  trace = new Trace();

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

  positionSmoothingSlider = cp5.addSlider("positionSmoothing")
    .setPosition(25, 3*25)
    .setRange(0.0, 1.0)
    .setColorValue(0xffaaaaaa)
    ;

  troubleshootingLabel = cp5.addTextlabel("troubleshootingLabel")
    .setText(troubleshootingText)
    .setPosition(25, 4*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 15))
    ;

  textInput = cp5.addTextfield("trackedId")
    .setPosition(25, 7*25)
    .setFocus(true)
    .setColor(color(255, 0, 0))
    ;

  List l = Arrays.asList("group centroid", "ind. centroid");
  /* add a ScrollableList, by default it behaves like a DropdownList */
  radioButton = cp5.addScrollableList("dropdown")
    .setPosition(25, 10*25)
    .setSize(200, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(l)
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
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

  trace.display(false);
  drawKeypoints();
}

void drawKeypoints() {
  for (String idString : group.keySet()) {
    for (String part : group.get(idString).keySet()) {
      PVector point = group.get(idString).get(part);
      //PVector velocity = velocities.get(part);
      if (point.z > 0.5) {
        float r = map(point.x, 0, 600, 64, 255);
        float g = map(point.y, 0, 500, 64, 255);
        float b = 100;

        //fill(random(128)+64, random(128)+64, random(128)+64);
        fill(r, g, b);
        //float base = map(velocity.mag(), 0, 30, 10, 36);

        //ellipse(point.x*2, point.y*2, random(base/3)+base, random(base/3)+base);
        ellipse(point.x*2, point.y*2, 10, 10);
      }

      fill(255);
        ellipse(centroids.get(idString).x*2, centroids.get(idString).y*2, 20, 20);
    }
  }

  fill(0, 0, 255);
  ellipse(generalCentroid.x*2, generalCentroid.y*2, 30, 30);
  trace.addPoint(new PVector(generalCentroid.x*2, generalCentroid.y*2));
}

void prepareUserHashMap(String idString) {
  group.put(idString, new HashMap<String, PVector>());
  String[] partNames = {
    "leftAnkle", 
    "leftEar", 
    "leftElbow", 
    "leftEye", 
    "leftHip", 
    "leftKnee", 
    "leftShoulder", 
    "leftWrist", 
    "nose", 
    "rightAnkle", 
    "rightEar", 
    "rightElbow", 
    "rightEye", 
    "rightHip", 
    "rightKnee", 
    "rightShoulder", 
    "rightWrist"
  };
  for (int i=0; i<partNames.length; i++) {
    group.get(idString).put(partNames[i], new PVector(0.0, 0.0, 0.0));
  }
}

/* incoming osc message are forwarded to the oscEvent method. */

void oscEvent(OscMessage theOscMessage) {
  float sumX = 0;
  float sumY = 0;
  int partCount = 0;

  if (theOscMessage.typetag().length() == 102) { // 17 arrays * 6 typetag chars per array
    String[] addressParts = theOscMessage.addrPattern().split("/");
    String idString = addressParts[4];
    //println(idString);

    if (group.get(idString) == null) {
      prepareUserHashMap(idString);
    }  

    inFlash = true; // post osc message received

    for (int i=0; i<101; i+=6) {
      String part = theOscMessage.get(i+1).stringValue();
      float score = theOscMessage.get(i+2).floatValue();
      float x = theOscMessage.get(i+3).floatValue();
      float y = theOscMessage.get(i+4).floatValue();

      if (score > 0.5) {
        sumX += x;
        sumY += y;
        partCount++;
      }

      PVector current = group.get(idString).get(part);
      PVector target = new PVector(x, y, score);
      //velocities.put(part, PVector.sub(current, target));
      current.lerp(target, 1 - positionSmoothing);
      group.get(idString).put(part, current); // score is stored as third component of the PVector
    }

    // now send some OSC messages to the LCP
    //PVector nose = positions.get("nose");
    //if (centroids.get(idString) == null){
    if (partCount > 0) {
      PVector currentCentroid;
      if (centroids.get(idString) == null) {
        currentCentroid = new PVector(sumX/partCount, sumY/partCount);
      } else {
        currentCentroid = centroids.get(idString);
      } 
      PVector targetCentroid = new PVector(sumX/partCount, sumY/partCount);
      currentCentroid.lerp(targetCentroid, 1 - 0.8);
      centroids.put(idString, currentCentroid);

      participatoryMessage(parseInt(idString));
    }
    //}
  }
}

void participatoryMessage(int id) {

  switch (participatoryMode) {
  case 0: // average all the individual centroids together
    float tempX = 0;
    float tempY = 0;

    for (String centroid : centroids.keySet()) {
      tempX += centroids.get(centroid).x;
      tempY += centroids.get(centroid).y;
    }

    generalCentroid.x = tempX/centroids.size();
    generalCentroid.y = tempY/centroids.size();
    break;
  case 1: // goes from one individual to the other
    if (trackedId == id) {
      generalCentroid.x = centroids.get(""+id).x;
      generalCentroid.y = centroids.get(""+id).y;
    }
    break;
  }

  // if at least one dancer being tracked?
  if (generalCentroid.x > 0 && generalCentroid.y > 0) {
    messagePrinter(generalCentroid.x, generalCentroid.y, true); // score is stored as third component of the PVector
  } else {
    // no parts are visible -- dancers are offscreen or not detected!
    messagePrinter(0.0, 0.0, false); // score is stored as third component of the PVector
  }
}

void messagePrinter(float x, float y, boolean flowActive) {
  outFlash = true;
  float xOut = map(x, 0, 600, 0, buildPlateWidth-1);
  float yOut = map(y, 0, 500, 0, buildPlateHeight-1);

  OscMessage position = new OscMessage("/lcp/control/position");

  position.add(xOut);
  position.add(yOut);
  position.add(105.0);
  oscP5.send(position, simulatorIAC); 

  OscMessage flow = new OscMessage("/lcp/control/flow");
  if (flowActive) {
    flow.add(2.5);
  } else {
    flow.add(0.0);
  }
  oscP5.send(flow, simulatorIAC);
}


public void trackedId(String theText) {
  // it becomes zero if not a number.  
  trackedId = parseInt(theText);
}

void dropdown(int n) {
  participatoryMode = n;
  println(n);

  /*CColor c = new CColor();
   c.setBackground(color(255, 0, 0));
   cp5.get(ScrollableList.class, "dropdown").getItem(n).put("color", c);*/
}

void keyReleased() {
  if (key == 's' || key == 'S') writeCSV();
  if (key == 'x' || key == 'X') reset();
}

void reset() {
  trace.resetDrawing();
}

void writeCSV() {
  trace.writeCSV();
}
