 //<>//
/**
 * listens for LCP control data via OSC, renders a simulation of LCP deposition behavior
 * 
 * OSC Inteface Vibe Proposal:
 * /lcp/control/position
 *   - list of three floats: x, y, z
 * /lcp/control/flow
 *   - one float:
 *     -> 0.0: off
 *     -> 0.5: droplets
 *     -> 1.0: stream
 * 
 * MOUSE
 * left-click drag   : LCP head position
 * right-click drag  : camera controls
 * 
 * KEYS
 * o                          : toggle OSC input active/bypass
 * l                          : toggle displaly strokes on/off
 * space                      : new noise seed
 * +                          : zoom in
 * -                          : zoom out
 * s                          : save png
 */

import processing.opengl.*;
import java.util.Calendar;
import controlP5.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
ControlP5 cp5;

Controller headPosXSlider, headPosYSlider, headPosZSlider, flowNormalizedSlider, instructionsLabel, frameRateLabel, depositionRateLabel;

// ------ mesh coloring ------
color strokeColor = color(255);
color floorColor = color(255);
color headColor = color(240);


// ------ mouse camera interaction ------
int offsetX = 0, offsetY = 0, clickX = 0, clickY = 0, zoom = 450;
float rotationX = 0, rotationZ = PI/4.0, targetRotationX = -PI/3, targetRotationZ = PI/4.0, clickRotationX, clickRotationZ; 

// ------ image output ------
int qualityFactor = 4;
boolean showStroke = false;

// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateWidthHalf = buildPlateWidth/2;
int buildPlateHeight = 280;
int buildPlateHeightHalf = buildPlateHeight/2;

int buildPlateDepth = 105;

// ------ state: head ------
float headPosX = buildPlateWidth/2;
float headPosY = buildPlateHeight/2;
float headPosXSmooth = buildPlateWidth/2;
float headPosYSmooth = buildPlateHeight/2;
int headPosZ = 105;
float smoothFactor = 0.25;

// ------ deposition ------
int dropletWidth = 3;
int dropletHeight = 2;
int verticalSteps = buildPlateDepth/dropletHeight;

float depositionSpeed = 2.5; // per second
float flowNormalized = 0.5;

int frameInterval = 4;
boolean c[][][] = new boolean[buildPlateWidth][buildPlateHeight][verticalSteps];

Artifact artifact;

// ------ OSC ------
boolean oscInputActive = true;

void setup() {
  frameRate(30);
  size(960, 1050, P3D);
  //ortho(-width/3, width/3, -height/3, height/3);
  smooth(8);
  colorMode(HSB, 360, 100, 100);
  cp5 = new ControlP5(this);
  oscP5 = new OscP5(this, 10420);
  cursor(CROSS);

  headPosXSlider =  cp5.addSlider("headPosX")
    .setPosition(25, 1*25)
    .setRange(0, 340)
    .setColorLabel(0)
    ;
  headPosYSlider =  cp5.addSlider("headPosY")
    .setPosition(25, 2*25)
    .setRange(0, 403-123)
    .setColorLabel(0)
    ;
  headPosZSlider =  cp5.addSlider("headPosZ")
    .setPosition(25, 3*25)
    .setRange(105, 170)
    .setColorLabel(0)
    ;

  flowNormalizedSlider = cp5.addSlider("flowNormalized")
    .setPosition(25, 4*25)
    .setRange(0.0, 1.0)
    .setColorLabel(0)
    .setLabel("deposition flow rate")
    ;

  instructionsLabel = cp5.addTextlabel("instructionsLabel")
    .setText("O key toggles OSC input \nR key resets buildplate \nright-click + drag to orbit scene \nleft-click + drag to deposit material")
    .setPosition(25, 5*25)
    .setColorValue(0xff000000)
    .setFont(createFont("Courier", 15))
    ;

  frameRateLabel = cp5.addTextlabel("frameRateLabel")
    .setText("n/a")
    .setPosition(25, 8*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 15))
    ;

  depositionRateLabel = cp5.addTextlabel("depositionRateLabel")
    .setText("n/a")
    .setPosition(25, 9*25)
    .setColorValue(0xffaaaaaa)
    .setFont(createFont("Courier", 15))
    ;

  artifact = new Artifact();
}

void draw() {
  updateTextLabels(); // frame rate, deposition rate

  if (showStroke) { 
    stroke(strokeColor);
  } else noStroke();

  background(0, 10, 100);
  lights();

  pushMatrix();
  
  // ------ camera control ------
  translate(width*0.5, height*0.5, zoom);

  if (mousePressed && mouseButton==RIGHT) {
    offsetX = mouseX-clickX;
    offsetY = mouseY-clickY;
    targetRotationX = min(max(clickRotationX + offsetY/float(width) * TWO_PI, -HALF_PI), HALF_PI);
    targetRotationZ = clickRotationZ + offsetX/float(height) * TWO_PI;
  }
  rotationX += (targetRotationX-rotationX)*0.1; 
  rotationZ += (targetRotationZ-rotationZ)*0.1;  
  rotateX(-rotationX);
  rotateZ(-rotationZ);
  // ------ end camera control ------


  // ------ head movement & deposition ------
  if (oscInputActive) {
    // execute the smoothing function (slider controller values already updated by osc event handler)
    headPosXSmooth += (headPosX-headPosXSmooth)*smoothFactor;
    headPosYSmooth += (headPosY-headPosYSmooth)*smoothFactor;
    
    // deposit the droplet
    deposit(int(headPosXSmooth), int(headPosYSmooth));
  } else {
    // mouse coords update head position
    headPosXSlider.setValue(map(mouseX, 0.0, width, 0, buildPlateWidth-1));
    headPosYSlider.setValue(map(mouseY, 0.0, width, 0, buildPlateHeight-1));
    
    // execute the smoothing function (slider controller values already updated by osc event handler)
    headPosXSmooth += (headPosX-headPosXSmooth)*smoothFactor;
    headPosYSmooth += (headPosY-headPosYSmooth)*smoothFactor;

    if (mousePressed && mouseButton==LEFT && !mousingControls()) {
      // deposit the droplet IF mouse pressed
      deposit(headPosXSmooth, headPosYSmooth);
    }
  }
  // ------ end head movement & deposition ------


  // ------ render floor, head, crystals ------
  drawFloor();
  drawHead();
  drawDeposition();
  // ------ end render floor, head, crystals ------

  popMatrix();
}

void deposit(float x, float y) {
  if (flowNormalized <= 0.0) return; // no flow!
  frameInterval = round(map(flowNormalized, 0.0, 1.0, 40, 22));
  if (frameCount % frameInterval == 0) {

    // search the vertical column at x,y from the top to the bottom
    for (int z = verticalSteps - 1; z>-1; z--) {
      int lowResX = round(x); 
      int lowResY = round(y);
      int lowResZ = z;
      
      lowResX = constrain(lowResX, 1, buildPlateWidth - 2);  //-2 because 0-based-index + 1-element-buffer
      lowResY = constrain(lowResY, 1, buildPlateHeight - 2);

      if ( // if deposition or floor is found one layer below in this column or neighboring column, add deposition by stacking
        lowResZ-1==0 || // the floor is below!
        c[lowResX][lowResY][lowResZ-1] || // this column-- well, one layer below actually
        c[lowResX+1][lowResY+1][lowResZ-1] || // immediate neighboring columns, one layer below
        c[lowResX-1][lowResY-1][lowResZ-1] ||
        c[lowResX+1][lowResY-1][lowResZ-1] ||
        c[lowResX-1][lowResY+1][lowResZ-1] ||
        c[lowResX+1][lowResY][lowResZ-1] ||
        c[lowResX-1][lowResY][lowResZ-1] ||
        c[lowResX][lowResY-1][lowResZ-1] ||
        c[lowResX][lowResY+1][lowResZ-1]
        ) {
        // time to deposit material
        
        if(c[lowResX][lowResY][lowResZ]) {
          break; // this column is full to the top. lets bounce out of here without depositing!
        }
        
        // implicit "else"
        c[lowResX][lowResY][lowResZ] = true; // mark presence of deposited material in 3d array
        
        artifact.deposit(lowResX, lowResY, lowResZ); // deposit in the artifact object for rendering
        
        break; // no need to inspect any lower in the column!
      }
    }
  }
}

void drawDeposition() {
  translate(-buildPlateWidthHalf, -buildPlateHeightHalf);
  stroke(color(0, 0, 200));
  artifact.display();
}

void updateTextLabels() {
  frameRateLabel.setStringValue(round(frameRate) + " fps");

  float depoRate = (frameRate/frameInterval) * dropletHeight;
  depositionRateLabel.setStringValue(nf(depoRate, 0, 1) + " mm/s");
}

boolean mousingControls() {
  return mouseX < 200 && mouseY < 200;
}

void drawFloor() {
  stroke(floorColor);
  box(buildPlateWidth, buildPlateHeight, 1);
}

void drawHead() {
  pushMatrix();
  stroke(headColor);
  translate(-buildPlateWidth/2, -buildPlateHeight/2);
  translate(headPosX, headPosY, 25 + headPosZ);
  box(3, 3, 50);
  popMatrix();
}

void mousePressed() {
  clickX = mouseX;
  clickY = mouseY;
  clickRotationX = rotationX;
  clickRotationZ = rotationZ;
}

void keyPressed() {
  if (key == '+') zoom += 20;
  if (key == '-') zoom -= 20;
}

void keyReleased() {  
  if (key == 's' || key == 'S') saveFrame(timestamp()+"_####.png");
  if (key == 'l' || key == 'L') showStroke = !showStroke;
  if (key == 'o' || key == 'O') oscInputActive = !oscInputActive;
  if (key == 'r' || key == 'R') reset();
  if (key == ' ') noiseSeed((int) random(100000));
}

void reset() {
  c = new boolean[buildPlateWidth][buildPlateHeight][verticalSteps];  
  artifact = new Artifact();
}

String timestamp() {
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance());
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

      headPosXSlider.setValue(xIn);
      headPosYSlider.setValue(yIn);
      headPosZSlider.setValue(zIn);
      return;
    }
  }

  if (theOscMessage.checkAddrPattern("/lcp/control/flow")) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("f")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float flow = theOscMessage.get(0).floatValue();  

      flowNormalizedSlider.setValue(flow);      
      return;
    }
  }

  return;
}
