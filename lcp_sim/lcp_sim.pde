
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
color strokeColor;

// ------ mouse camera interaction ------
int offsetX = 0, offsetY = 0, clickX = 0, clickY = 0, zoom = 200;
float rotationX = 0, rotationZ = PI/4.0, targetRotationX = -PI/3, targetRotationZ = PI/4.0, clickRotationX, clickRotationZ; 

// ------ image output ------
int qualityFactor = 4;
boolean showStroke = true;

// ------ build plate ------
int buildPlateWidth = 340;
int buildPlateWidthHalf = buildPlateWidth/2;
int buildPlateHeight = 280;
int buildPlateHeightHalf = buildPlateHeight/2;

// ------ state: head ------
int headPosX = buildPlateWidth/2;
int headPosY = buildPlateHeight/2;
int headPosZ = 105;

// ------ deposition ------
int dropletDiameter = 3;
int dropletHeight = 1;
float depositionSpeed = 2.5; // per second
int heightMax = 600; // 105;
int verticalSteps = heightMax/dropletHeight;

int resolutionDivisor = 4;
boolean c[][][] = new boolean[buildPlateWidth/resolutionDivisor][buildPlateHeight/resolutionDivisor][verticalSteps/resolutionDivisor];

ShapeContainer container;

// ------ perlin walk ------
boolean walkActive = true;
PVector p;
PVector pOld;
float stepSize = 1.2;
float noiseScale = 100; 
float noiseStrength = 20;
float noiseZ, noiseZVelocity = 0.01;
float angle;



void setup() {
  //fullScreen(P3D);
  size(800, 800, P3D);
  colorMode(HSB, 360, 100, 100);
  cp5 = new ControlP5(this);
  cursor(CROSS);
  
  p = new PVector(buildPlateWidthHalf, buildPlateHeightHalf);
  pOld = p.copy();
  smooth();

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
    .setRange(105, 170)
    .setColorLabel(0)
    ;
  
  container = new ShapeContainer(c);
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


  if (walkActive) {
    angle = noise(p.x/noiseScale, p.y/noiseScale, noiseZ) * noiseStrength;
    p.x += cos(angle) * stepSize;
    p.y += sin(angle) * stepSize;
    
    headPosX = int(p.x);
    headPosY = int(p.y);

    deposit(headPosX, headPosY);
    
    // offscreen wrap
    if (p.x<10) p.x=pOld.x=325;
    if (p.x>330) p.x=pOld.x=15;
    if (p.y<10) p.y=pOld.y=265;
    if (p.y>270) p.y=pOld.y=15;
    
    pOld.set(p);
    noiseZ += noiseZVelocity;
    
  } else {

    // ------ head movement ------
    if (mousePressed && mouseButton==LEFT && !mousingControls()) {
      headPosX = int(map(constrain(mouseX, 0, height), 0.0, width, 0, buildPlateWidth));
      headPosY = int(map(constrain(mouseY, 0, height), 0.0, width, 0, buildPlateHeight));
      deposit(headPosX, headPosY);
    }
  }

  drawFloor();
  drawHead();
  drawDeposition();

  popMatrix();
}

void deposit(int x, int y) {
  // search the column
  for(int z = verticalSteps/resolutionDivisor -1; z>-1; z--) {
    int lowResX = floor(float(x)/resolutionDivisor);
    int lowResY = floor(float(y)/resolutionDivisor);
    int lowResZ = floor(float(z)/resolutionDivisor);

    if (
    c[lowResX][lowResY][lowResZ] ||
    c[lowResX+1][lowResY+1][lowResZ] ||
    c[lowResX-1][lowResY-1][lowResZ] ||
    c[lowResX+1][lowResY-1][lowResZ] ||
    c[lowResX-1][lowResY+1][lowResZ] ||
    
    c[lowResX+2][lowResY][lowResZ] ||
    c[lowResX-2][lowResY][lowResZ] ||
    c[lowResX][lowResY-2][lowResZ] ||
    c[lowResX][lowResY+2][lowResZ] ||
    z==0) {
      c[floor(float(x)/resolutionDivisor)][floor(float(y)/resolutionDivisor)][floor(float(z)/resolutionDivisor) + 1] = true;
      container.deposit(x, y, z);
      break;
    }
  }
}

void drawDeposition() {
  translate(-buildPlateWidthHalf, -buildPlateHeightHalf);
  container.display();
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
  if (key == 'w' || key == 'W') walkActive = !walkActive;
  if (key == 'r' || key == 'R') reset();
  if (key == ' ') noiseSeed((int) random(100000));
}

void reset() {
  for(int x=0; x<c.length; x++) {
        for(int y=0; y<c[x].length; y++) {
          for(int z=0; z<c[x][y].length; z++) {
            c[x][y][z] = false;
          }
        }
      }
      
  container = new ShapeContainer(c);
}

String timestamp() {
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", Calendar.getInstance());
}
