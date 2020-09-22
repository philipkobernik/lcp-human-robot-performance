import java.util.*;
import oscP5.*;
import netP5.*;
import controlP5.*;

OscP5 oscP5;
NetAddress simulatorIAC;
ControlP5 cp5;

controlP5.Controller oscInLabel, oscOutLabel, troubleshootingLabel;
controlP5.Slider sliderPlaybackTimer;
controlP5.RadioButton tracesStyleButton;
// timer to control the playback speed
double timer = 500;
double currentTime;


// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateWidthHalf = buildPlateWidth/2;
int buildPlateHeight = 280;
int buildPlateHeightHalf = buildPlateHeight/2;

// ------ other ------
boolean inFlash, outFlash = false;
String troubleshootingText = "If not receiving OSC: \n"
  + "1. is posenet tracker running? \n"
  + "2. is firebase-osc-relay running? \n\n"
  + "press 'x' key to reset";

// Note the HashMap's "key" is a String and "value" is an Integer
HashMap<String, PVector> keypoints = new HashMap<String, PVector>();
ArrayList<Sequence> sequences = new ArrayList<Sequence>();
int currentSequence = 0;
int currentLoop = 0;

boolean recording = false;

int currentPlaybackSequence = 0;

int toggleTracesStyle = 1;

int scaledWidth = 1200;
int scaledHeight = 1000;

String focusPart = "nose";
BodyParts bodyPartsManager;

void setup() {
  size(1200, 1000, P3D);
  frameRate(20);
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
  /* add a ScrollableList, by default it behaves like a DropdownList */
  //cp5.addScrollableList("what_part_draws")
  //  .setPosition(25, 11.5*25)
  //  .setSize(100, 450)
  //  .setBarHeight(20)
  //  .setItemHeight(20)
  //  .addItems(focusPartList)
  //  .setColorForeground(color(120))
  //  .setColorBackground(color(60))
  //  .setColorActive(color(200))
  //  .setColorLabel(color(200))
  //  ;

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

  sliderPlaybackTimer = cp5.addSlider("playbackTimer")
    .setPosition(25, 9*25)
    .setRange(0, 1000)
    .setColorForeground(color(120))
    .setColorBackground(color(60))
    .setColorActive(color(200))
    .setColorLabel(color(200))
    ;


  tracesStyleButton = cp5.addRadioButton("tracesStyle")
    .setPosition(25, 10*25)
    .addItem("lines", 1)
    .addItem("dots", 2)
    .setColorForeground(color(120))
    .setColorBackground(color(60))
    .setColorActive(color(200))
    .setColorLabel(color(200))
    ;

  messagePrinter(0, 0, false); // start with flow off.
  bodyPartsManager = new BodyParts();
}

void draw() {
  // keep traces alive
  drawTraces();
  timer = sliderPlaybackTimer.getValue();

  int red = recording ? 200 : 0;
  fill(red, 0, 0, 255);
  noStroke();
  rect(0, 0, width, height);

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

  updateFlashingDots();
  drawKeypoints();
}

Sequence getPlaybackSeq() {
  return sequences.get(currentPlaybackSequence);
}

void drawTraces() {
  for (int i = 0; i < currentPlaybackSequence; i++) {
    sequences.get(i).drawTraces();
  }
}

void drawKeypoints() {

  for (Map.Entry<String, PVector> keypoint : keypoints.entrySet()) {
    PVector point = keypoint.getValue();
    String partName = keypoint.getKey();

    if (point.z > 0.5) {
      float r = map(point.x, 0, 600, 64, 255);
      float g = map(point.y, 0, 500, 64, 255);
      float b = 100;

      noStroke();

      fill(r, g, b);
      ellipse(
        map(point.x, 0, 600, 0, scaledWidth), 
        map(point.y, 0, 500, 0, scaledHeight), 
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

  //focus on
  fill(255, 255, 255);
  ellipse(
    map(bodyPartsManager.position(focusPart).x, 0, 600, 0, scaledWidth), 
    map(bodyPartsManager.position(focusPart).y, 0, 500, 0, scaledHeight), 
    random(6)+26, 
    random(6)+26
    );
}

void updateFlashingDots() {
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
      keypoints.put(part, new PVector(x, y, score)); // score is stored as third component of the PVector
    }

    //PVector centroid = new PVector(sumX/partCount, sumY/partCount);
    //PVector rightWrist = keypoints.get("");

    // now send some OSC messages to the LCP
    if (partCount > 0) {
      //PVector centroid = new PVector(sumX/partCount, sumY/partCount);

      //messagePrinter(centroid.x, centroid.y, true); // score is stored as third component of the PVector
    } else {
      // no parts are visible -- dancer is offscreen or not detected!
      //messagePrinter(0.0, 0.0, false); // score is stored as third component of the PVector
    }


    // add pose and centroid to the sequence 
    if (recording) {
      sequences.get(sequences.size()-1).addPose(
        new HashMap<String, PVector>(keypoints), 
        keypoints.get(focusPart)
        );
    }
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
    flow.add(7.5);
  } else {
    flow.add(0.0);
  }
  oscP5.send(flow, simulatorIAC);
}

void toggleRecording() {
  recording = !recording;

  if (recording) {
    sequences.add(new Sequence());
  } else {
    // end the sequence, maybe calculate number loops or something
    sequences.get(sequences.size()-1).stopRecording();
  }
}

void tracesStyle(int a) {
  toggleTracesStyle = a;
}

void reset() {
  keypoints = new HashMap<String, PVector>();
  sequences = new ArrayList<Sequence>();
  currentSequence = 0;
  currentLoop = 0;
  recording = false;
  currentPlaybackSequence = 0;
  messagePrinter(0, 0, false); // start with flow off
}

void keyReleased() {
  if (key == 'r' || key == 'R') toggleRecording();
  if (key == 'x' || key == 'X') reset();
}

void what_part_draws(int dropdownIndex) {
  /* request the selected item based on index n */
  focusPart = (String)cp5.get(ScrollableList.class, "what_part_draws").getItem(dropdownIndex).get("text");
}
