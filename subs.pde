void drawFace(Surface S, int faceIndex, int theStroke, int theFill) {
  if (theStroke == -1) {
    noStroke();
  } else {
    stroke(theStroke);
  }
  if (theFill == -1) {
    noFill();
  } else {
    fill(theFill);
  }
  Face f = S.faces.get(faceIndex);
  int n = f.vertices.size();
  PVector p;
  beginShape();
  //println(f);
  for (int i=0; i<n; i++) {
    int vertexIndex = f.vertices.get(i);
    p = S.positions.get(vertexIndex);
    //println(p);
    vertex(p.x, p.y, p.z);
  }
  p = S.positions.get(f.vertices.get(0));
  vertex(p.x, p.y, p.z); // closes the face
  endShape();
}


Surface tetrahedron() {
  Surface S = new Surface("");
  S.nV = 4;
  S.nE = 4;
  S.nF = 4;
  S.positions.add(new PVector(0.0,0.0,width/2));
  S.positions.add(new PVector(0,0,0));
  S.positions.add(new PVector(width/2,0,0));
  S.positions.add(new PVector(0,width/2,0));
  println(S.positions.get(0));
  println(S.positions.get(1));
  println(S.positions.get(2));
  println(S.positions.get(3));
  ArrayList<Integer> temp0 = new ArrayList<Integer>();
  temp0.add(1);
  temp0.add(3);
  temp0.add(2);
  Face f0 = new Face(new ArrayList<Integer>(temp0));
  S.faces.add(f0);
  ArrayList<Integer> temp1 = new ArrayList<Integer>();
  temp1.add(0);
  temp1.add(2);
  temp1.add(3);
  Face f1 = new Face(temp1);
  S.faces.add(f1);
  ArrayList<Integer> temp2 = new ArrayList<Integer>();
  temp2.add(0);
  temp2.add(3);
  temp2.add(1);
  Face f2 = new Face(temp2);
  S.faces.add(f2);
  ArrayList<Integer> temp3 = new ArrayList<Integer>();
  temp3.add(0);
  temp3.add(1);
  temp3.add(2);
  Face f3 = new Face(temp3);
  S.faces.add(f3);
  return(S);

}