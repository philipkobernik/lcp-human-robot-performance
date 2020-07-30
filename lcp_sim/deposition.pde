class Deposition {

  PShape part;
  float partSize;
  
  Deposition(int x, int y, int z) {
    partSize = resolutionDivisor;
    part = createShape(BOX, partSize, partSize, partSize/2);
    part.translate(x, y, z*0.5);
  }

  PShape getShape() {
    return part;
  }

}
