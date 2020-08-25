class Trace {
  ArrayList<PVector> path = new ArrayList<PVector>();
  int currentPosition = 0;
  PVector noiseVector = new PVector(0,0);
  float noiseFactor = 5;

  Trace() {
  }

  void display(int index, boolean noise) {
    beginShape();
    // tracing phase
    for (int i = 0; i < index; i++) {
      strokeWeight(10*(i+1)/path.size());
      //strokeWeight(10*map(i, 0, index, 0, 1));
      stroke(color(map(i, 0, index+1, 50, 255)));
      noFill(); //<>//
      
      if (noise){
        strokeWeight(1);
        //strokeWeight(10*map(i, 0, index, 0, 1));
        stroke(color(50));
        noiseVector.x = random(0,1);
        noiseVector.y = random(0,1);
      }
      vertex(path.get(i).x + noiseFactor*noiseVector.x, path.get(i).y + noiseFactor*noiseVector.y);
      noiseVector.x = 0;
      noiseVector.y = 0;
    }
    endShape();
  }
  
  void addPoint(PVector p){
    path.add(p); //<>//
  }
  
}
