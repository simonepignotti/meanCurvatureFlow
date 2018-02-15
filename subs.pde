
void drawFace(Surface S, int faceIndex, int theStroke, int theFill, PApplet g) {
  if (theStroke == -1) {
    g.noStroke();
  } else {
    g.stroke(theStroke);
  }
  if (theFill == -1) {
    g.noFill();
  } else {
    g.fill(theFill);
  }
  Face f = S.faces.get(faceIndex);
  int n = f.vertices.size();
  PVector p;
  g.beginShape();
  //println(f);
  for (int i=0; i<n; i++) {
    int vertexIndex = f.vertices.get(i);
    p = S.positions.get(vertexIndex);
    //println(p);
    g.vertex(p.x, p.y, p.z);
  }
  p = S.positions.get(f.vertices.get(0));
  g.vertex(p.x, p.y, p.z); // closes the face
  g.endShape();
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

void applyFlow(MyWinData data) {
    Surface S = data.S;
    int flow = data.flow % 10;
    int renormalizationType = data.flow / 10;
    float tau = data.tau;
    float initialVol = data.initialVol;
    switch(flow) {
        case 1:
          applyFlowVolumeRenorm(S,S.meanCurvatureFlow(),initialVol,tau);
          break;
        case 2:
          applyFlowProj(S,S.meanCurvatureFlow(),initialVol,tau);
          break;
      }
  }

  void applyFlowProj(Surface S, PVector[] flow, float initialVol, float tau) {

    PVector[] grad = S.gradient();
    PVector[] newFlow = new PVector[S.nV];
    PVector f, g;
    float gNorm, dotP, volAfter;

    for (int i=0; i<S.nV; i++) {
      g = grad[i];
      f = flow[i];
      gNorm = g.x * g.x + g.y * g.y + g.z * g.z;;
      dotP = f.x*g.x + f.y*g.y + f.z*g.z;
      dotP /= gNorm;
      println(f);
      println(g.mult(dotP));
      newFlow[i] = PVector.sub(f,g.mult(dotP)).mult(tau);
    }

    for (int i=0; i<S.nV; i++) {
      S.positions.get(i).add(newFlow[i]);
    }

    volAfter = S.volume();
    if (abs(initialVol-volAfter) > 0.1) {
      println("WARNING: the volume is not conserved, applying manual conservation");
      println(abs(initialVol-volAfter));
      // float ratio = (float) Math.pow(initialVol/volAfter, 1.0/3);
      // for(int i=0; i<S.nV; i++) {
      //   S.positions.get(i).mult(ratio);
      // }
    }

  }

  void applyFlowVolumeRenorm(Surface S, PVector[] flow, float initialVol, float tau) {

    for (int i=0; i<S.nV; i++) {
      // if (!boundaryVertices.contains(i))
        S.positions.get(i).add(flow[i].mult(tau));
    }

    float volAfter = S.volume();
    float ratio = (float) Math.pow(initialVol/volAfter, 1.0/3);

    for(int i=0; i<S.nV; i++) {
      S.positions.get(i).mult(ratio);
    }

  }
