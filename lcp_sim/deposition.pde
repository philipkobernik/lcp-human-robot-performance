class Deposition {

  PShape deposition;

  Deposition(int x, int y, int z) {
    deposition = createShape(BOX, dropletWidth, dropletWidth, dropletHeight);
    deposition.translate(x, y, z * dropletHeight);
  }

  PShape getShape() {
    return deposition;
  }
}
