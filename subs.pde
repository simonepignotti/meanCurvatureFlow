
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

// apply a flow to the surface of a given window
void applyFlow(MyWinData data) {
  Surface S = data.S;
  int flow = data.flow;
  float tau = data.tau;
  float initialVol = data.initialVol;
  switch(flow) {
    case 1:
      applyFlowRenorm(S,S.meanCurvatureFlow(),initialVol,tau);
      break;
    case 2:
      applyFlowProj(S,S.meanCurvatureFlow(),initialVol,tau);
      break;
    case 3:
      applyFlowRenorm(S,S.harmonicFlow(),initialVol,tau);
      break;
    case 4:
      applyFlowProj(S,S.harmonicFlow(),initialVol,tau);
      break;
    case 5:
      applyFlowRenorm(S,S.harmonicAreaFlow(),initialVol,tau);
      break;
    case 6:
      applyFlowProj(S,S.harmonicAreaFlow(),initialVol,tau);
      break;
    case 7:
      applyFlowRenorm(S,S.squaredMeanCurvatureFlow(),initialVol,tau);
      break;
    case 8:
      applyFlowProj(S,S.squaredMeanCurvatureFlow(),initialVol,tau);
      break;
    default:
      break;
  }
}

// apply the flow after projecting it on the volume constraints
void applyFlowProj(Surface S, PVector[] flow, float initialVol, float tau) {

  PVector[] grad = S.gradient();
  PVector[] newFlow = new PVector[S.nV];
  PVector f, g;
  // gNorm: norm of the gradient
  // dotP: dot product between the flow and the gradient
  float gNorm, dotP, volAfter;

  for (int i=0; i<S.nV; i++) {
    g = grad[i];
    f = flow[i];
    gNorm = g.x * g.x + g.y * g.y + g.z * g.z;;
    dotP = f.x*g.x + f.y*g.y + f.z*g.z;
    dotP /= gNorm;
    // equivalent:
    // gNorm = g.mag();
    // dotP = f.dot(g)/gNorm;
    // println(f);
    // println(PVector.mult(g, dotP));
    newFlow[i] = PVector.sub(f,PVector.mult(g, dotP)).mult(tau);
  }

  for (int i=0; i<S.nV; i++) {
    S.positions.get(i).add(newFlow[i]);
  }

  // apply renormalization if the volume varied too much due to numerical errors
  volAfter = S.volume();
  if (abs(initialVol-volAfter) > 0.1) {
    println("WARNING: the volume is not conserved, applying manual conservation");
    println(abs(initialVol-volAfter));
    float ratio = (float) Math.pow(initialVol/volAfter, 1.0/3);
    for(int i=0; i<S.nV; i++) {
      S.positions.get(i).mult(ratio);
    }
  }

}

// apply the flow after normalizing it to keep the volume constant with respect to the original value
void applyFlowRenorm(Surface S, PVector[] flow, float initialVol, float tau) {

  for (int i=0; i<S.nV; i++) {
    if (!S.boundaryVertices.contains(i))
      S.positions.get(i).add(flow[i].mult(tau));
  }

  float volAfter = S.volume();
  float ratio = (float) Math.pow(initialVol/volAfter, 1.0/3);

  for(int i=0; i<S.nV; i++) {
    S.positions.get(i).mult(ratio);
  }

}
