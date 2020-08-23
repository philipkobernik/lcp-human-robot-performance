class Deposition {

  PShape deposition;

  Deposition(int x, int y, int z) {
    // create the shape representing deposition
    sphereDetail(6);
    deposition = createShape(SPHERE, dropletHeight);
    
    // translate the shape to its rightful position
    deposition.translate(x, y, z * dropletHeight);
  }

  PShape getShape() {
    return deposition;
  }
}
