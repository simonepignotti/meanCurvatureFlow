int nVmax = 5000;
int nFmax = 10000;
float distance = 2;  // for camera

boolean flowing = false;
float tau = 0.1;
Surface S;

void setup() {
  size(500, 500, P3D);
  //S = new Surface("sphere10-20.txt");
  S = new Surface("mug.txt");
  //S = new Surface("shapes/cube.txt");
  //S = new Surface("dodecahedron.txt");
  //S = new Surface("icosphere_4.txt");
  //S = new Surface("icosphereBB.txt");
  
  println("Print : \n ");
  println("\n 1 :  " + pointsDansOrdre(1));
  println("\n 2 :  " + pointsDansOrdre(2));
  println("\n 3 :  " + pointsDansOrdre(3));
  println("\n 4 :  " + pointsDansOrdre(4));
  println("\n 5 :  " + pointsDansOrdre(5));
  
}

void draw() {
  background(50);
  camera(distance*width/2.0, distance*height/2.0, distance*(height/2.0) / tan(PI*30.0 / 180.0), 
  width/2.0, height/2.0, 0, 0, 1, 0);
  translate(width/2, height/2, 0);
  rotateX(TWO_PI*mouseY/width);
  rotateY(TWO_PI*mouseX/width);
  // axes
  line(0,0,0,width/2,0,0);
  line(0,0,0,0,width/2,0);
  line(0,0,0,0,0,width/2);
  
  if(flowing) {
    flowHarmoniqueContrain();
    
    //float v = volumeOfS();
    //flowHarmonique();
    //float v2 = volumeOfS();
    //v = v / v2;
    //v = pow(v,1.0/3);
    //homotecieOnS(v);
    
  }
  
  S.drawSurface();
  
}

void mouseWheel(MouseEvent event) {  // for zooming in and out
  float e = event.getCount();
  distance += e/100;
}


void keyReleased() {
  
  if (key == 'f') {
    flowing = !flowing;
    println("Flowing = ", flowing);
  }
  
  if (key == 'd') {
    flowHarmoniqueContrain();
    println("1 Flowing ");
  }
  
  if (key == 'v') {
    println("Volume : " + volumeOfS());
  }
  
  if (key == 'o') {
    tau += 0.1;
    println("tau : " + tau);
  }
  if (key == 'p') {
    tau -= 0.1;
    println("tau : " + tau);
  }
  if (key == 'l') {
    tau += 0.01;
    println("tau : " + tau);
  }
  if (key == 'm') {
    tau -= 0.01;
    println("tau : " + tau);
  }
}

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