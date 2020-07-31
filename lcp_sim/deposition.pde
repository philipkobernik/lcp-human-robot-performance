class Deposition {

  PShape part;
  float partSize;
  float partHeight = float(dropletHeight);
  
  Deposition(int x, int y, int z) {
    if(resolutionDivisor == 1) {
      partSize = float(dropletWidth);
      part = createShape(BOX, partSize, partSize, partHeight);
      part.translate(x * resolutionDivisor, y * resolutionDivisor, z * resolutionDivisor * partHeight);
    } else {
      partSize = resolutionDivisor*0.9;
      part = createShape(BOX, partSize, partSize, partSize * 0.666);
      part.translate(x * resolutionDivisor, y * resolutionDivisor, z * resolutionDivisor * 0.666);
    }
  }

  PShape getShape() {
    return part;
  }

}
