class Deposition {

  PShape deposition;

  Deposition(int x, int y, int z) {
    // create the shape representing desosition
    sphereDetail(6);
    deposition = createShape(SPHERE, dropletWidth);
    
    // translate the shape to its rightful position
    deposition.translate(x, y, z * dropletHeight);
  }

  PShape getShape() {
    return deposition;
  }
}
