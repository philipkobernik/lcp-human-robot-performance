class Sequence {
  // attributes
  ArrayList<HashMap<String, PVector>> poses;
  ArrayList<PVector> centroids;
  int nbOfLoops = 10; // should it be defined at the start or defined by the end of the recording?
  int currentLoop = 0;
  int replayIndex = 0;
  boolean _isRecording = true;

  // functions
  Sequence() {
    poses = new ArrayList<HashMap<String, PVector>>();
    centroids = new ArrayList<PVector>();
  }

  // display as it's being recorded
  // display as it's being replayed
  void display() {
    //draw connection between parts
    drawConnections();

    // amount of Loops
    noStroke();
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

  void addPose(HashMap<String, PVector> pose, PVector centroid) {
    poses.add(pose);
    centroids.add(centroid);
  }

  void setNumberofLoops(int nbLoops) {
    nbOfLoops = nbLoops;
  }

  void incrementIndex() {
    replayIndex++;
    if (replayIndex == poses.size()) {
      currentLoop++;
      replayIndex = 0;
    }
  }

  boolean isDone() {
    return (replayIndex == poses.size()-1 && currentLoop == nbOfLoops);
  }
  boolean isRecording() {
    return _isRecording;
  }
  void stopRecording() {
    _isRecording = false;
  }

  void drawConnections() {
    stroke(200);
    PVector lShoulder = poses.get(replayIndex).get("leftShoulder");
    PVector rShoulder = poses.get(replayIndex).get("rightShoulder");
    drawLine(lShoulder, rShoulder);

    // Left Arm
    PVector lElbow = poses.get(replayIndex).get("leftElbow");
    drawLine(lShoulder, lElbow);
    PVector lWrist = poses.get(replayIndex).get("leftWrist");
    drawLine(lElbow, lWrist);

    // Right Arm
    PVector rElbow = poses.get(replayIndex).get("rightShoulder");
    drawLine(rShoulder, rElbow);
    PVector rWrist = poses.get(replayIndex).get("rightWrist");
    drawLine(rElbow, rWrist);

    // Trunk
    PVector lHip = poses.get(replayIndex).get("leftHip");
    PVector rHip = poses.get(replayIndex).get("rightHip");
    drawLine(lHip, rHip);
    drawLine(lShoulder, lHip);
    drawLine(rShoulder, rHip);

    // Left Leg
    PVector lKnee = poses.get(replayIndex).get("leftKnee");
    drawLine(lHip, lKnee);
    PVector lAnkle = poses.get(replayIndex).get("leftAnkle");
    drawLine(lKnee, lAnkle);

    // Left Leg
    PVector rKnee = poses.get(replayIndex).get("rightKnee");
    drawLine(rHip, rKnee);
    PVector rAnkle = poses.get(replayIndex).get("rightAnkle");
    drawLine(rKnee, rAnkle);
   
  }

  void drawLine(PVector p1, PVector p2) {
    if (p1.z > 0.5 && p2.z > 0.5) {
      line(p1.x, p1.y, p2.x, p2.y);
    }
  }
}
