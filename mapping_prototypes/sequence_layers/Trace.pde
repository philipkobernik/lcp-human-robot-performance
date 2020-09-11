class Trace { //<>// //<>//
  ArrayList<PVector> path = new ArrayList<PVector>();
  int currentPosition = 0;
  PVector noiseVector = new PVector(0, 0);
  float noiseFactor = 5;
  ArrayList<ArrayList<PVector>> dotsPosition = new ArrayList<ArrayList<PVector>>();
  int numberOfLoops;
  int currentLoop = 0;

  Trace(int nbLoops) {
    numberOfLoops = nbLoops;
  }

  void display(int index, int loop, boolean noise) {
    if (toggleTracesStyle == 1) {
      beginShape();
      // tracing phase
      for (int i = 0; i < index; i++) {
        strokeWeight(10*(i+1)/path.size());
        //strokeWeight(10*map(i, 0, index, 0, 1));
        stroke(color(map(i, 0, index+1, 50, 255)));
        noFill();

        if (noise) {
          strokeWeight(1);
          //strokeWeight(10*map(i, 0, index, 0, 1));
          stroke(color(50));
          noiseVector.x = random(-1, 1);
          noiseVector.y = random(-1, 1);
        }
        vertex(path.get(i).x + noiseFactor*noiseVector.x, path.get(i).y + noiseFactor*noiseVector.y);
        noiseVector.x = 0;
        noiseVector.y = 0;
      }
      endShape();
    } else if (toggleTracesStyle == 2) {
      for (int i = 0; i < index; i++) {
      if (i == 0){
        dotsPosition.add(new ArrayList<PVector>());
      }
        strokeWeight(1);
        //strokeWeight(10*map(i, 0, index, 0, 1));
        stroke(color(50));
    
        dotsPosition.get(loop).add(new PVector(random(-1, 1), random(-1, 1)));

        noStroke();
        fill(255, 10);
        ellipse(path.get(i).x + noiseFactor*dotsPosition.get(loop).get(i).x, path.get(i).y +dotsPosition.get(loop).get(i).y, 10, 10);
      }
    }
  }

  void addPoint(PVector p) {
    path.add(p);
  }
}
