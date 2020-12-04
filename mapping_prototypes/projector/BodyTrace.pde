class BodyTrace {
  ArrayList<PVector> path = new ArrayList<PVector>();
  int currentPosition = 0;
  PVector noiseVector = new PVector(0, 0);
  float noiseFactor = 5;
  ArrayList<ArrayList<PVector>> dotsPosition = new ArrayList<ArrayList<PVector>>();


  BodyTrace() {
  }

  void display(boolean noise) {
    beginShape();
    // tracing phase
    for (int i = 0; i < path.size(); i++) {
      strokeWeight(5);
      //strokeWeight(10*map(i, 0, index, 0, 1));
      stroke(color(map(i, 0, path.size(), 50, 255)));
      noFill();

      if (noise) {
        strokeWeight(1);
        //strokeWeight(10*map(i, 0, index, 0, 1));
        stroke(color(50));
        noiseVector.x = random(-1, 1);
        noiseVector.y = random(-1, 1);
      }

      //int scaledWidth = 1200;
      //int scaledHeight = 1000;
      /*vertex(
       map(path.get(i).x, 0, 600, 0, scaledWidth) + noiseFactor*noiseVector.x, 
       map(path.get(i).y, 0, 600, 0, scaledHeight) + noiseFactor*noiseVector.y
       );*/

      vertex(path.get(i).x + noiseFactor*noiseVector.x, path.get(i).y + noiseFactor*noiseVector.y);
      noiseVector.x = 0;
      noiseVector.y = 0;
    }
    endShape();
    
    noStroke();
    strokeWeight(1);
    //} else if (toggleTracesStyle == 2) {
    //  for (int i = 0; i < index; i++) {
    //    if (i == 0) {
    //      dotsPosition.add(new ArrayList<PVector>());
    //    }
    //    strokeWeight(1);
    //    //strokeWeight(10*map(i, 0, index, 0, 1));
    //    stroke(color(50));

    //    dotsPosition.get(loop).add(new PVector(random(-1, 1), random(-1, 1)));

    //    noStroke();
    //    fill(255, 10);
    //    ellipse(
    //      map(path.get(i).x, 0, 600, 0, scaledWidth) + noiseFactor*dotsPosition.get(loop).get(i).x, 
    //      map(path.get(i).y, 0, 600, 0, scaledHeight) + dotsPosition.get(loop).get(i).y, 
    //      10, 
    //      10
    //      );
    //  }
    //}
  }

  void addPoint(PVector p) {
    path.add(p);
  }
  void resetDrawing() {
    path.clear();
  }
  void writeCSV() {
    println("write CSV");
  }
}
