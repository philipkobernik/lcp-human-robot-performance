class Deposition {

  PShape part;
  float partSize = float(dropletWidth);
  float partHeight = float(dropletHeight);

  Deposition(int x, int y, int z) {
    part = createShape(BOX, partSize, partSize, partHeight);
    part.translate(x, y, z * partHeight);
  }

  PShape getShape() {
    return part;
  }
}
