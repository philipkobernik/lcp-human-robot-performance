class ShapeContainer {
  ArrayList<Deposition> artifact;

  PShape depositionShape;

  ShapeContainer() {
    artifact = new ArrayList<Deposition>();
    depositionShape = createShape(PShape.GROUP);
  }
  
  void deposit(int x, int y, int z) {
    Deposition d = new Deposition(x, y, z);
    artifact.add(d);
    depositionShape.addChild(d.getShape());
  }

  void display() {
    shape(depositionShape);
  }
}
