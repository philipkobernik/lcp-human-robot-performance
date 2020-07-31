
/**
 * listens for LCP control data via OSC, renders a simulation of LCP deposition behavior
 * 
 * OSC Inteface Vibe Proposal:
 * /lcp/control/pos
 *   - list of three floats: x, y, z
 * /lcp/control/flow
 *   - one float:
 *     -> 0.0: off
 *     -> 0.5: droplets
 *     -> 1.0: stream
 * 
 * MOUSE
 * position x/y + left drag   : LCP head position
 * position x/y + right drag  : camera controls
 * 
 * KEYS
 * l                          : toogle displaly strokes on/off
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

Controller headPosXSlider, headPosYSlider, headPosZSlider, resolutionDivisorSlider, flowNormalizedSlider, instructionsLabel;

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

// ------ state: head ------
float headPosX = buildPlateWidth/2;
float headPosY = buildPlateHeight/2;
float headPosXSmooth = buildPlateWidth/2;
float headPosYSmooth = buildPlateHeight/2;
int headPosZ = 105;

// ------ deposition ------
int dropletDiameter = 3;
int dropletHeight = 1;
float depositionSpeed = 2.5; // per second
float flowNormalized = 0.5;
int heightMax = 1000; // 105;
int verticalSteps = heightMax/dropletHeight;

int resolutionDivisor = 3;
int frameInterval = 4;
boolean c[][][] = new boolean[buildPlateWidth/resolutionDivisor][buildPlateHeight/resolutionDivisor][verticalSteps/resolutionDivisor];

ShapeContainer container;

// ------ OSC ------
boolean oscInputActive = true;

void setup() {
  //fullScreen(P3D);
  size(800, 800, P3D);
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

  resolutionDivisorSlider = cp5.addSlider("resolutionDivisor")
    .setPosition(25, 4*25)
    .setRange(1, 8)
    .setColorLabel(0)
    .setNumberOfTickMarks(8)
    ;

  flowNormalizedSlider = cp5.addSlider("flowNormalized")
    .setPosition(25, 5*25)
    .setRange(0.0, 1.0)
    .setColorLabel(0)
    .setLabel("deposition flow rate")
    ;

  instructionsLabel = cp5.addTextlabel("label")
    .setText("O key toggles OSC input \nR key resets buildplate \nright-click + drag to orbit scene \nleft-click + drag to deposit material")
    .setPosition(25, 6*25)
    .setColorValue(0xff000000)
    .setFont(createFont("Courier", 15))
    ;

  container = new ShapeContainer(c);
}

void draw() {

  if (showStroke) { 
    stroke(strokeColor);
  } else noStroke();

  background(0, 10, 100);
  lights();

  // ------ set view ------
  pushMatrix();
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

  if (oscInputActive) {
    headPosXSmooth += (headPosX-headPosXSmooth)*0.05;
    headPosYSmooth += (headPosY-headPosYSmooth)*0.05;
    deposit(int(headPosXSmooth), int(headPosYSmooth));
  } else {
    // ------ head movement ------
    headPosXSlider.setValue(map(constrain(mouseX, 0, height), 0.0, width, 0, buildPlateWidth));
    headPosYSlider.setValue(map(constrain(mouseY, 0, height), 0.0, width, 0, buildPlateHeight));
    headPosXSmooth += (headPosX-headPosXSmooth)*0.05;
    headPosYSmooth += (headPosY-headPosYSmooth)*0.05;

    if (mousePressed && mouseButton==LEFT && !mousingControls()) {
      deposit(headPosXSmooth, headPosYSmooth);
    }
  }

  drawFloor();
  drawHead();
  drawDeposition();

  popMatrix();
}

void deposit(float x, float y) {
  if (flowNormalized <= 0.0) return;
  frameInterval = round(map(flowNormalized, 0.0, 1.0, 8.0, 1.0));
  if (frameCount % frameInterval == 0) {

    // search the column at x,y from the top to the bottom

    for (int z = verticalSteps/resolutionDivisor -1; z>-1; z--) {
      int lowResX = round(x/resolutionDivisor);
      int lowResY = round(y/resolutionDivisor);
      int lowResZ = round(float(z)/resolutionDivisor);

      if ( // if any deposition found in this column or neighboring column, add deposition by stacking
        c[lowResX][lowResY][lowResZ-1] ||
        c[lowResX+1][lowResY+1][lowResZ-1] ||
        c[lowResX-1][lowResY-1][lowResZ-1] ||
        c[lowResX+1][lowResY-1][lowResZ-1] ||
        c[lowResX-1][lowResY+1][lowResZ-1] ||
        c[lowResX+1][lowResY][lowResZ-1] ||
        c[lowResX-1][lowResY][lowResZ-1] ||
        c[lowResX][lowResY-1][lowResZ-1] ||
        c[lowResX][lowResY+1][lowResZ-1] ||

        // expands the neighbor-search radius
        //c[lowResX+2][lowResY][lowResZ-1] ||
        //c[lowResX-2][lowResY][lowResZ-1] ||
        //c[lowResX][lowResY-2][lowResZ-1] ||
        //c[lowResX][lowResY+2][lowResZ-1] ||
        lowResZ-1==0) {
        c[lowResX][lowResY][lowResZ] = true;
        container.deposit(lowResX, lowResY, lowResZ);
        break;
      }
    }
  }
}

void drawDeposition() {
  translate(-buildPlateWidthHalf, -buildPlateHeightHalf);
  stroke(color(0, 0, 200));
  container.display();
}

boolean mousingControls() {
  return mouseX < 200 && mouseY < 200;
}

void drawFloor() {
  fill(floorColor);
  box(buildPlateWidth, buildPlateHeight, 1);
}

void drawHead() {
  pushMatrix();
  fill(headColor);
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
  c = new boolean[buildPlateWidth/resolutionDivisor][buildPlateHeight/resolutionDivisor][verticalSteps/resolutionDivisor];  
  container = new ShapeContainer(c);
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.getName() == "resolutionDivisor") {
    reset();
  }
}

String timestamp() {
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance());
}

void oscEvent(OscMessage theOscMessage) {
  if (!oscInputActive) return;

  if (theOscMessage.checkAddrPattern("/lcp/control/position")==true) {
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

  if (theOscMessage.checkAddrPattern("/lcp/control/flow")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("f")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float flow = theOscMessage.get(0).floatValue();  

      flowNormalizedSlider.setValue(flow);      
      return;
    }
  }
}
