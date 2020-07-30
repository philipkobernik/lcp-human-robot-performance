class ShapeContainer {
  ArrayList<Deposition> depos;

  PShape depositionShape;

  ShapeContainer(boolean[][][] c) {
    depos = new ArrayList<Deposition>();
    depositionShape = createShape(PShape.GROUP);
  }
  
  void deposit(int x, int y, int z) {
    Deposition p = new Deposition(x, y, z);
    depos.add(p);
    depositionShape.addChild(p.getShape());
  }

  void display() {
    shape(depositionShape);
  }
}
