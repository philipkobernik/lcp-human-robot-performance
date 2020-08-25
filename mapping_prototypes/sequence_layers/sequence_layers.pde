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
ArrayList<Sequence> sequences = new ArrayList<Sequence>();

boolean recording = false;

int currentPlaybackSequence = 0;
int currentPlaybackLoop;

void setup() {
  size(600, 500, P3D);
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
  // STATE in the prototype:
  // 1. stack of sequences, (array of Sequence instances)
  //    -- each has number of loops (layers)
  // 2. current sequence
  // 3. current loop

  // keep traces alive
  drawTraces();

  fill(0, 0, 0, 255);
  noStroke();
  rect(0, 0, width, height);

  // FOR PLAYBACK
  if (sequences.size() > currentPlaybackSequence && !getPlaybackSeq().isRecording()) {
    // -- ask current seq if its done?
    if (getPlaybackSeq().isDone()) {
      // advance to next sequence
      currentPlaybackSequence++;
      //currentPlaybackSequence = (currentPlaybackSequence + 1) % sequences.size(); // loop around here
    } else {
      getPlaybackSeq().incrementIndex();
      getPlaybackSeq().display();
    }

    //getPlaybackSeq().display();
    // -- if not, advance current seq frame
    // -- render frame pose
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
  for (PVector point : keypoints.values()) {
    if (point.z > 0.5) {
      float r = map(point.x, 0, 600, 64, 255);
      float g = map(point.y, 0, 500, 64, 255);
      float b = 100;

      //fill(random(128)+64, random(128)+64, random(128)+64);
      fill(r, g, b);
      noStroke();
      ellipse(point.x, point.y, random(6)+13, random(6)+13);
    }
  }
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

void oscEvent(OscMessage theOscMessage) {
  float sumX = 0;
  float sumY = 0;
  int partCount = 0;
  if (theOscMessage.typetag().length() == 102 && theOscMessage.checkAddrPattern("/lcp/tracking/pose")) { // 17 arrays * 6 typetag chars per array
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
      keypoints.put(part, new PVector(x, y, score)); // score is stored as third component of the PVector
    }

    PVector centroid = new PVector(sumX/partCount, sumY/partCount);


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
        centroid
        );
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
    flow.add(2.5);
  } else {
    flow.add(0.0);
  }
  oscP5.send(flow, simulatorIAC);
}

void sendSequenceToPrinter(ArrayList<PVector> centroids, int nbLayers) {

  OscMessage positions = new OscMessage("/lcp/control/positions");
  for (PVector centroid : centroids) {
    float cX = map(centroid.x, 0, 600, 0, buildPlateWidth-1);
    float cY = map(centroid.y, 0, 500, 0, buildPlateHeight-1);

    positions.add(cX);
    positions.add(cY);
    positions.add(105.0);
  }
  positions.add(nbLayers);
  oscP5.send(positions, simulatorIAC);

  OscMessage layers = new OscMessage("/lcp/control/layers");
  layers.add(nbLayers);
  oscP5.send(layers, simulatorIAC);
}

void toggleRecording() {
  recording = !recording;

  if (recording) {
    sequences.add(new Sequence());
    //
  } else {
    // end the sequence, maybe calculate number loops or something
    //
    sequences.get(sequences.size()-1).stopRecording();
    println("recording end");
    // send OSC
    // - centroids array
    // - number of loops
    sendSequenceToPrinter(sequences.get(sequences.size()-1).centroids, sequences.get(sequences.size()-1).nbOfLoops);
  }
}

void keyReleased() {
  if (key == 'r' || key == 'R') toggleRecording();
}
