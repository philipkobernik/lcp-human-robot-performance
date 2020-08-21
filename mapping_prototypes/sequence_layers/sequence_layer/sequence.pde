class Sequence {
  // attributes
  ArrayList<HashMap<String, PVector>> poses;
  int nbOfLoops = 0; // should it be defined at the start or defined by the end of the recording?
  int replayIndex = 0;

  // functions
  Sequence() {
  }

  // display as it's being recorded
  // display as it's being replayed
  void display() {
    // amount of Loops
    for (PVector point : poses.get(replayIndex).values()) {
      if (point.z > 0.5) {
        float r = map(point.x, 0, 600, 64, 255);
        float g = map(point.y, 0, 500, 64, 255);
        float b = 100;

        //fill(random(128)+64, random(128)+64, random(128)+64);
        fill(r, g, b);
        ellipse(point.x, point.y, random(6)+13, random(6)+13);
      }
    }
  }

  void addPose(HashMap<String, PVector> pose) {
    poses.add(pose);
  }

  void setNumberofLoops(int nbLoops) {
    nbOfLoops = nbLoops;
  }

  void incrementIndex() {
    replayIndex++;
  }
}
