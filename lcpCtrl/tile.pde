class tile {

  PVector pos;
  color c = color(0, 0, 0);
  float r = 9.5;

  tile(int x, int y) {
    pos = new PVector(x, y);
  }

  void render() {
    fill(c);
    noStroke();
    rectMode(CENTER);
    rect(pos.x,pos.y,r,r);
  }
}
