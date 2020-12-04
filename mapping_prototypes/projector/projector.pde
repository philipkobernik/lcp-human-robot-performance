import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.*;

OscP5 oscP5;
NetAddress simulatorIAC;
ControlP5 cp5;

Controller oscInLabel, oscOutLabel, positionSmoothingSlider, troubleshootingLabel, textInput, radioButton, nameDropdown;
controlP5.Slider sliderPlaybackTimer;
// timer to control the playback speed
double timer = 500;
double currentTime;

BodyTrace bodyTrace;

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
//HashMap<String, HashMap<String, PVector>> group = new HashMap<String, HashMap<String, PVector>>();
//HashMap<String, PVector> velocities = new HashMap<String, PVector>();

// Note the HashMap's "key" is a String and "value" is an Integer
HashMap<String, PVector> keypoints = new HashMap<String, PVector>();
ArrayList<Sequence> sequences = new ArrayList<Sequence>();
int currentSequence = 0;
int currentLoop = 0;
boolean recording = false;
int currentPlaybackSequence = 0;

// smoothing
float positionSmoothing = 0.25;

// participatory option
int mode = 1;
PVector nozzlePosition;

// mode 0
HashMap<String, PVector> centroids = new HashMap<String, PVector>();
PVector generalCentroid = new PVector(0, 0);

// mode 1
// black rectangle

int inputCoordsHeight = 1080;
int inputCoordsWidth = 1920;

int scaledWidth = 960;
int scaledHeight = 540;

String focusPart = "nose";
BodyParts bodyPartsManager;

void setup() {
  //size(960, 540, P3D);
  fullScreen(P3D);
  frameRate(30);
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

  List focusPartList = Arrays.asList("rightKidney", "leftKidney", "hyoidBone", "leftVestibular", "jadePillow", "leftShoulder", "rightShoulder", "leftElbow", "rightElbow", "leftWrist", "rightWrist", "leftHip", "rightHip", "leftKnee", "rightKnee", "leftAnkle", "rightAnkle");
  List focusPartList2 = Arrays.asList("rightKidney", "leftKidney", "hyoidBone", "leftVestibular", "jadePillow", "rightFibula", "aorta", "heartAndLungs", "perineum", "tail", "leftFloatingRibs", "rightDistalRadius");

  // we position the printer nozzle in the middle of the canvas first
  //nozzlePosition =  new PVector(width/2, height/2);
  bodyTrace = new BodyTrace();

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

  sliderPlaybackTimer = cp5.addSlider("playbackTimer")
    .setPosition(25, 9*25)
    .setRange(0, 1000)
    .setColorForeground(color(120))
    .setColorBackground(color(60))
    .setColorActive(color(200))
    .setColorLabel(color(200))
    ;

  bodyPartsManager = new BodyParts();
}

void draw() {
  // keep traces alive

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

  if (mode == 0) {
    /*drawTraces();
     timer = sliderPlaybackTimer.getValue();
     
     // FOR PLAYBACK
     if (sequences.size() > currentPlaybackSequence && !getPlaybackSeq().isRecording()) {
     // -- ask current seq if its done?
     if (getPlaybackSeq().isDone()) {
     // advance to next sequence
     currentPlaybackSequence++;
     currentTime = millis();
     //currentPlaybackSequence = (currentPlaybackSequence + 1) % sequences.size(); // loop around here
     } else {
     if (millis()-currentTime > timer) {
     getPlaybackSeq().incrementIndex();
     currentTime = millis();
     }
     getPlaybackSeq().display();
     }
     } 
     */

    bodyTrace.display(false);
    drawKeypoints();
  }
}

Sequence getPlaybackSeq() {
  return sequences.get(currentPlaybackSequence);
}

void drawKeypoints() {
  if (keypoints.size() == 0) return;
  stroke(255);
  strokeWeight(5);
  drawConnections(keypoints);

  for (Map.Entry<String, PVector> keypoint : keypoints.entrySet()) {
    PVector point = keypoint.getValue();
    String partName = keypoint.getKey();


    if (point.z > 0.5) {
      float r = map(point.x, 0, inputCoordsWidth, 64, 255);
      float g = map(point.y, 0, inputCoordsHeight, 64, 255);
      float b = 100;

      noStroke();

      //fill(r, g, b);
      fill(255);
      ellipse(
        map(point.x, 0, inputCoordsWidth, 0, scaledWidth), 
        map(point.y, 0, inputCoordsHeight, 0, scaledHeight), 
        random(6)+13, 
        random(6)+13
        );

      /*if (partName.equals(focusPart)) {
       fill(255, 255, 255);
       ellipse(
       map(point.x, 0, 600, 0, scaledWidth), 
       map(point.y, 0, 500, 0, scaledHeight), 
       random(6)+26, 
       random(6)+26
       );
       } else {
       fill(r, g, b);
       ellipse(
       map(point.x, 0, 600, 0, scaledWidth), 
       map(point.y, 0, 500, 0, scaledHeight), 
       random(6)+13, 
       random(6)+13
       );
       }*/
    }
  }

  //body part where focus is on
  //fill(255, 255, 255);
  float bodyPartX = map(bodyPartsManager.position(focusPart).x, 0, inputCoordsWidth, 0, scaledWidth);
  float bodyPartY = map(bodyPartsManager.position(focusPart).y, 0, inputCoordsHeight, 0, scaledHeight);

  ellipse(
    map(bodyPartsManager.position(focusPart).x, 0, inputCoordsWidth, 0, scaledWidth), 
    map(bodyPartsManager.position(focusPart).y, 0, inputCoordsHeight, 0, scaledHeight), 
    random(6)+26, 
    random(6)+26
    );

  bodyTrace.addPoint(new PVector(bodyPartX, bodyPartY));
}

void drawLine(PVector p1, PVector p2) {
  if (p1.z > 0.5 && p2.z > 0.5) {
    line(
      map(p1.x, 0, 1920, 0, scaledWidth), 
      map(p1.y, 0, 1080, 0, scaledHeight), 
      map(p2.x, 0, 1920, 0, scaledWidth), 
      map(p2.y, 0, 1080, 0, scaledHeight)
      );
  }
}

void drawConnections(HashMap<String, PVector> poses) {
  PVector lShoulder = poses.get("leftShoulder");
  PVector rShoulder = poses.get("rightShoulder");
  drawLine(lShoulder, rShoulder);

  // Left Arm
  PVector lElbow = poses.get("leftElbow");
  drawLine(lShoulder, lElbow);
  PVector lWrist = poses.get("leftWrist");
  drawLine(lElbow, lWrist);

  // Right Arm
  PVector rElbow = poses.get("rightElbow");
  drawLine(rShoulder, rElbow);
  PVector rWrist = poses.get("rightWrist");
  drawLine(rElbow, rWrist);

  // Trunk
  PVector lHip = poses.get("leftHip");
  PVector rHip = poses.get("rightHip");
  drawLine(lHip, rHip);
  drawLine(lShoulder, lHip);
  drawLine(rShoulder, rHip);

  // Left Leg
  PVector lKnee = poses.get("leftKnee");
  drawLine(lHip, lKnee);
  PVector lAnkle = poses.get("leftAnkle");
  drawLine(lKnee, lAnkle);

  // Left Leg
  PVector rKnee = poses.get("rightKnee");
  drawLine(rHip, rKnee);
  PVector rAnkle = poses.get("rightAnkle");
  drawLine(rKnee, rAnkle);
}

/*void prepareUserHashMap(String idString) {
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
 }*/

/* incoming osc message are forwarded to the oscEvent method. */

void oscEvent(OscMessage message) {
  float sumX = 0;
  float sumY = 0;
  int partCount = 0;

  if (message.typetag().length() == 102 && message.checkAddrPattern("/lcp/tracking/pose")) { // 17 arrays * 6 typetag chars per array
    inFlash = true; // post osc message received

    for (int i=0; i<101; i+=6) {
      String part = message.get(i+1).stringValue();
      float score = message.get(i+2).floatValue();
      float x = message.get(i+3).floatValue();
      float y = message.get(i+4).floatValue();

      /*if (score > 0.5) {
       sumX += x;
       sumY += y;
       partCount++;
       }*/

      //PVector current = group.get(idString).get(part);
      //PVector target = new PVector(x, y, score);
      //velocities.put(part, PVector.sub(current, target));
      //current.lerp(target, 1 - positionSmoothing);
      //group.get(idString).put(part, current); // score is stored as third component of the PVector
      keypoints.put(part, new PVector(x, y, score));
    }

    // now send some OSC messages to the LCP
    //PVector nose = positions.get("nose");
    //if (centroids.get(idString) == null){
    /*if (partCount > 0) {
     PVector currentCentroid;
     if (centroids.get(idString) == null) {
     currentCentroid = new PVector(sumX/partCount, sumY/partCount);
     } else {
     currentCentroid = centroids.get(idString);
     } 
     PVector targetCentroid = new PVector(sumX/partCount, sumY/partCount);
     currentCentroid.lerp(targetCentroid, 1 - 0.8);
     centroids.put(idString, currentCentroid);
     }*/
    //}
  }

  if (message.checkAddrPattern("/lcp/control/focusPart")) {
    String part = message.get(0).stringValue();
    focusPart = part;
  }

  if (message.checkAddrPattern("/lcp/control/recording")) {
    int isRecording = message.get(0).intValue();

    recording = isRecording == 1; // manually re-cast from integer to boolean in java

    if (recording) {
      sequences.add(new Sequence());
    } else {
      // end the sequence, maybe calculate number loops or something
      sequences.get(sequences.size()-1).stopRecording();
    }
  }
}


void keyReleased() {
  if (key == 's' || key == 'S') writeCSV();
  if (key == 'x' || key == 'X') reset();
  if (key == 'b' || key == 'B') {
    // 
    mode = 1;
  }
}

void reset() {
  bodyTrace.resetDrawing();
}

void writeCSV() {
  bodyTrace.writeCSV();
}
