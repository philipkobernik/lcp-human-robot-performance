Table table;
IntList times = new IntList();
ArrayList<PVector> positions = new ArrayList<PVector>();
int currentPos = 0;
int currentTime = 0;

void setup() {
  size(960, 540);

  table = loadTable("centroids-cat-lake-3.csv", "header");

  println(table.getRowCount() + " total rows in table");

  for (TableRow row : table.rows()) {
    int id = row.getInt("timeId");
    times.append(id);
    float x = row.getFloat("y")/465*1920/2;
    float y = row.getFloat("x")/365*1080/2;
    positions.add(new PVector(x,y));
  }
  
  background(0);
}

void draw(){
  if (currentPos < positions.size()-1){
    if (millis() > (currentTime-times.get(0))){
      currentPos++;
    }
    
    noStroke();
    fill(255,10);
    ellipse(positions.get(currentPos).x+random(-5,5), positions.get(currentPos).y+random(-5,5), 10,10);
    currentTime = times.get(currentPos+1);
  }
}
