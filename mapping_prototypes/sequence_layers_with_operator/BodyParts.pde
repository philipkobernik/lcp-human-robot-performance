class BodyParts {
  ArrayList<String> parts;
  float scoreThreshold = 0.5;

  BodyParts() {
  }

  /*right Kidney, left kidney (mid way down on the spine, protected by lower ribs), 
   hyoid bone (upper throat), left vestibular (ear), jade pillow (cerebellum), 
   right fibula (outside of lower leg), aorta (a whole area or random area in this vertical, central place of blood flow), 
   heart and lungs, perineum (lowest central root of body), tail (slightly higher and to the back from perineum), 
   left glenoid fossa (shoulder), liver, pancreas, right achilles tendon (just above heel), left floating ribs, 
   thyroid (lower throat), adrenals (central and lower than the heart), right distal radius and ulna attachment (wrist), 
   lower lumbar spine, left ischium (pelvic half), manubrium (below where collar bones), 
   right toes, left toes, right finger tips, left finger tips. 
   */
  PVector position(String part) {
    // RIGHT KIDNEY
    PVector pos = new PVector(keypoints.get("nose").x, keypoints.get("nose").y);
    float scoreRS = keypoints.get("rightShoulder").z;
    float scoreRH = keypoints.get("rightHip").z;
    if (part.equals("rightKidney") && scoreRS > scoreThreshold && scoreRH > scoreThreshold) {
      pos = (keypoints.get("rightShoulder").add(keypoints.get("rightHip"))).div(2);
    }
    
    // LEFT KIDNEY
    float scoreLS = keypoints.get("leftShoulder").z;
    float scoreLH = keypoints.get("leftHip").z;
    if (part.equals("leftKidney") && scoreLS > scoreThreshold && scoreLH > scoreThreshold) {
      pos = (keypoints.get("leftShoulder").add(keypoints.get("leftHip"))).div(2);
    }
    
    // HYOID BONE
    float scoreN = keypoints.get("nose").z;
    if (part.equals("hyoidBone") && scoreLS > scoreThreshold && scoreRS > scoreThreshold && scoreN > scoreThreshold) {
      pos = (keypoints.get("leftShoulder").add(keypoints.get("rightShoulder")).add(keypoints.get("nose"))).div(3);
    }
    
    // LEFT VESTIBULAR
    float scoreLE = keypoints.get("leftEar").z;
    if (part.equals("leftVestibular") && scoreLE > scoreThreshold) {
      pos = keypoints.get("leftEar");
    }
    
    // JADE PILLOW
    float scoreRE = keypoints.get("rightEar").z;
    if (part.equals("jadePillow") && scoreLE > scoreThreshold && scoreRE > scoreThreshold) {
      pos = (keypoints.get("leftEar").add(keypoints.get("rightEar"))).div(2);
    }
    
    return pos;
  }
}
