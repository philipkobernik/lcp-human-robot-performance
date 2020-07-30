
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
ControlP5 cp5;

Controller headPosXSlider;
Controller headPosYSlider;
Controller headPosZSlider;

// ------ mesh coloring ------
color midColor, topColor, bottomColor;
color strokeColor;
float threshold = 0.30;

// ------ mouse camera interaction ------
int offsetX = 0, offsetY = 0, clickX = 0, clickY = 0, zoom = 200;
float rotationX = 0, rotationZ = PI/4.0, targetRotationX = -PI/3, targetRotationZ = PI/4.0, clickRotationX, clickRotationZ; 

// ------ image output ------
int qualityFactor = 4;
boolean showStroke = true;

// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateHeight = 280;

// ------ state: head ------
int headPosX = buildPlateWidth/2;
int headPosY = buildPlateHeight/2;
int headPosZ = 105;


void setup() {
  //fullScreen(P3D);
  size(800, 800, P3D);
  colorMode(HSB, 360, 100, 100);
  cp5 = new ControlP5(this);
  cursor(CROSS);

  // colors
  topColor = color(6, 55, 55); //color(0, 0, 100); // dark blue
  midColor = color(6, 35, 75); //color(191, 99, 63); 
  bottomColor = color(6, 35, 75); //color(0, 0, 0); // black

  strokeColor = color(0, 0, 0);
  smooth();

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
    .setRange(105, 180)
    .setColorLabel(0)
    ;
}

void draw() {

  if (showStroke) stroke(strokeColor);
  else noStroke();

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
  rotationX += (targetRotationX-rotationX)*0.25; 
  rotationZ += (targetRotationZ-rotationZ)*0.25;  
  rotateX(-rotationX);
  rotateZ(-rotationZ); 


  // ------ head movement ------
  if (mousePressed && mouseButton==LEFT && !mousingControls()) {
    float headPosXFloat = map(mouseX, 0.0, width, 0, buildPlateWidth);
    headPosX = int(headPosXFloat);
    
    headPosY = int(map(mouseY, 0, width, 0, buildPlateHeight));
  }

  drawFloor();
  drawHead();

  popMatrix();

}

boolean mousingControls() {
  return mouseX < 200 && mouseY < 100;
}

void drawFloor() {
  box(buildPlateWidth, buildPlateHeight, 1);
}

void drawHead() {
  pushMatrix();
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
  if (key == ' ') noiseSeed((int) random(100000));
}

String timestamp() {
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance());
}
