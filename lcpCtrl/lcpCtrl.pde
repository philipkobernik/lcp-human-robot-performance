import processing.serial.*;
Serial myPort;
int cmdCount = 0;

ArrayList<tile> tiles = new ArrayList<tile>();
float printerX, printerY;
int speed = 100; // mm/sec

String sheetName = "centroids2.csv";
Table centroids;
int rowCount;
int row = 1;
boolean start = false;
ArrayList<PVector> vecs = new ArrayList<PVector>();

void setup() {
  //size(730, 930); // printer dimensions: x: 365 y: 465 (window scaled by 2 for interface purposes 
  size(400, 200);


  // initialize tiles
  //for (int i=5; i<730; i+=10) {
  //  for (int j=5; j<height; j+=10) {
  //    tiles.add(new tile(i, j));
  //  }
  //}

  loadData();  

  // initialize serial connection
  printArray(Serial.list());
  myPort = new Serial(this, Serial.list()[1], 115200);
  myPort.write("start");
  println(myPort.read());
}


void draw() {
  background(240, 170, 153);

  if (start) {
    if (frameCount % 2 == 0) {
      //for (int i=0; i<vecs.size(); i++) {    
      printerX = vecs.get(row).x;
      printerY = vecs.get(row).y;
      if (row==0) {
        speed = 1500;
      } else {
        speed = 200;
      }
      myPort.write("G1 F" + speed + "\r\n");
      myPort.write("G1 X"+ printerX + " Y" + printerY + "\r\n");
      stroke(255);
      fill(255);
      println("curr row: "+ row);
      row++;
      //}
    }
  }
  //for (tile t : tiles) {
  //  t.render();
  //}
}
