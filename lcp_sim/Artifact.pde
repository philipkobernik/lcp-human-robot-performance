class Artifact {
  ArrayList<Deposition> artifact;

  PShape shapeGroup;

  Artifact() {
    artifact = new ArrayList<Deposition>();
    shapeGroup = createShape(PShape.GROUP);
  }
  
  void deposit(int x, int y, int z) {
    Deposition d = new Deposition(x, y, z);
    artifact.add(d);
    shapeGroup.addChild(d.getShape());
  }

  void display() {
    shape(shapeGroup);
  }
}
