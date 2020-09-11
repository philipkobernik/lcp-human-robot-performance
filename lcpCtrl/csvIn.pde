void loadData() {
  centroids = loadTable(sheetName, "header");

  rowCount = centroids.getRowCount();

  for (int i=0; i<rowCount; i++) {
    PVector p = new PVector(centroids.getFloat(i, 1), centroids.getFloat(i, 2));
    vecs.add(p);
  }
}
