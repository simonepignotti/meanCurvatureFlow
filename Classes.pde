class Face {
  // faces are oriented
  ArrayList<Integer> vertices = new ArrayList<Integer>();

  Face(ArrayList<Integer> list) {
    for (int i=0; i<list.size(); i++) {
      this.vertices.add(list.get(i));
    }
  }
}

class Surface {
  int nV;
  int nE;
  int nF;   // number of vertices, edges and faces
  ArrayList<PVector> positions = new ArrayList<PVector>();
  ArrayList<Face> faces = new ArrayList<Face>();
  ArrayList<Integer> boundaryVertices = new ArrayList<Integer>();
  boolean[][] incidenceVF = new boolean[nVmax][nFmax]; // true iff v is in f
  boolean[][] adjacency = new boolean[nVmax][nVmax]; // true iff v1 ~ v2

  void drawSurface() {

    for (int i=0; i<this.nF; i++) {
      drawFace(this, i, 250, 137);
    }

    // draw vertices
    // for(i=0; i< this.nV; i++) {
    // pushMatrix();
    // println(positions.get(i).x,positions.get(i).y,positions.get(i).z);
    // translate(positions.get(i).x,positions.get(i).y,positions.get(i).z);
    // sphere(10);
    // popMatrix();
    // }

  }

  // void drawSurfaceMCFColoring() {
  //   int i;
  //   float max = 0;
  //   PVector[] mcf = S.meanCurvatureFlow(tau);
  //   float volBefore = this.volume();
  //   float[] colors = new float[nV];
  //   for (int j=0; j<mcf.length; j++) {
  //     if (mcf[j].mag() > max) {
  //       max = mcf[j].mag();
  //     }
  //   }
  //   for (int j=0; j<mcf.length; j++) {
  //     colors[j] = mcf[j].mag()*255/max;
  //   }
  //   for (i=0; i<this.nF; i++) {
  //     drawFace(this, i, 250, 137, colors);
  //   }
  //   int count = 0;
  //   for (i=0; i<this.nV; i++) {
  //     PVector m = mcf[i];
  //     if (m.mag()<1) {
  //       this.positions.get(i).add(m);
  //     }
  //     else {
  //       count++;
  //     }
  //   }
  //   println(count);
  //   float volAfter = this.volume();
  //   float ratio = (float) Math.pow(volBefore/volAfter, 1.0/3);
  //   for(i=0; i<nV; i++) {
  //     positions.get(i).mult(ratio);
  //   }
  // }

  Surface(String filename) {
    String[] lines = loadStrings(filename);  // in data folder

    // cleans the matrices first
    for(int i=0; i<nVmax; i++) {
      for(int j=0;j<nFmax;j++) {
        this.incidenceVF[i][j] = false;
      }
      for(int j=0;j<nVmax;j++) {
        this.adjacency[i][j] = false;
      }
    }

    boolean end_header = false;
    String plyTest = "ply";
    if (!lines[0].equals(plyTest)) exit();
    float scalingFactor = width/2;  // assumes coordinates in the PLY file are in [-1,1]

    int i = 0; // line currently read in the PLY file
    while (!end_header) {
      String[] keywords = split(lines[i], ' ');
      if (keywords[0].equals("element")) {
        if (keywords[1].equals("vertex")) {
          this.nV = int(keywords[2]);
        } else if (keywords[1].equals("face")) {
          this.nF = int(keywords[2]);
        }
      } else if (keywords[0].equals("end_header")) {
        end_header = true;
      }
      i++;
    }
    println("v=", this.nV, " f=", this.nF);

    // Vertex' 3D coordinates
    for (int j = 0; j < this.nV; j++) {
      String[] keywords = split(lines[i], ' ');
      //println("lines[] " + i + " : " + lines[i]);
      //println("keywords: " + keywords.length);
      this.positions.add(new PVector(scalingFactor*float(keywords[0]),
          scalingFactor*float(keywords[1]), scalingFactor*float(keywords[2])));
      i++;    // increase line number
    }

    // faces' indexes
    for(int j=0; j< this.nF; j++) {
      String[] keywords = split(lines[i], ' ');
      ArrayList<Integer> indexes = new ArrayList<Integer>();
      int degree = int(keywords[0]);
      for(int k=1; k<=degree; k++) {
        int vIndex = int(keywords[k]);
        indexes.add(vIndex);
        this.incidenceVF[vIndex][j] = true;  // vIndex is in face j
      }
      Face f = new Face(indexes);
      this.faces.add(f);
      i++;
      // fills the adjacency matrix
      for(int k=0; k<degree; k++) {
        this.adjacency[indexes.get(k)][indexes.get((k+1) % degree)] = true;
        this.adjacency[indexes.get((k+1) % degree)][indexes.get(k)] = true;
      }
    }

    for (int j=0; j<this.nV; j++) {
      if (isBoundaryVertex(j))
        boundaryVertices.add(j);
    }

  }

  float volume() {

    float v = 0;
    int degree = 0;
    PVector p1, p2, p3;

    for (Face f:faces) {
      degree = f.vertices.size();
      for (int i=0; i<=degree-3; i++) {
        p1 = positions.get(f.vertices.get(0));
        p2 = positions.get(f.vertices.get(i+1));
        p3 = positions.get(f.vertices.get(i+2));
        v += (p1.cross(p2).dot(p3));
      }
    }

    return v/6;

  }

  //return true if P_i is a boundary vertex
  boolean isBoundaryVertex(int i) {

    boolean boundary = true;
    int nhbr=0; //number of neighboring vertices
    int vf=0; // number of faces containing P_i

    for (int j=0; j<nV; j++) {
      if(adjacency[i][j])
         nhbr++;
    }

    for (int f=0; f<nF; f++){
      if(incidenceVF[i][f])
          vf++;
    }

    if (nhbr == vf)
       boundary = false;

    return boundary;

  }

  void applyFlowProj(PVector[] flow, float tau) {
    return;
  }

  void applyFlowRenorm(PVector[] flow, float initialVol, float tau) {

    for (int i=0; i<this.nV; i++) {
      // if (!boundaryVertices.contains(i))
        this.positions.get(i).add(flow[i].mult(tau));
    }

    float volAfter = this.volume();
    float ratio = (float) Math.pow(initialVol/volAfter, 1.0/3);

    for(int i=0; i<nV; i++) {
      positions.get(i).mult(ratio);
    }

  }

  PVector[] gradient() {

    PVector[] grad = new PVector[nV];
    Face face;
    PVector p1, p2, g;
    int degree, idx;

    for(int i=0; i<nV; i++) {

      if (boundaryVertices.contains(i)) {
        grad[i] = new PVector(0,0,0);
      }
      else {

        g = new PVector(0,0,0);

        for (int f=0; f<this.nF; f++) {
          if(this.incidenceVF[i][f]) {
            face = this.faces.get(f);
            idx = face.vertices.indexOf(i);
            degree = face.vertices.size();

            for(int j=1; j<degree-1; j++) {
              p1 = this.positions.get(face.vertices.get((idx+j) % degree));
              p2 = this.positions.get(face.vertices.get((idx+j+1) % degree));
              g.add(p1.cross(p2)); // pas divisé par 6 (car pas utile)
            }
          }
        }
        grad[i] = g;
      }
    }
    return grad;
  }

  PVector[] harmonicFlow() {
    PVector[] hf = new PVector[nV];
    PVector h = new PVector(0,0,0);

    for(int i=0; i<nV; i++) {
      if(!boundaryVertices.contains(i)){
        h.set(0,0,0);
        int nA = 0;
        for(int j=0; j<nV; j++) {
          if (adjacency[i][j] == true) {
            nA++;
            h.add(positions.get(j));
          }
        }
        h.div(nA);
        hf[i] = h.copy();
      }
    }
    return hf;
  }

    //harmonic flow divided by the area
   void harmonicAreaFlow(float tau) {
    ArrayList<PVector> hf = new ArrayList<PVector>();
    ArrayList<PVector> niebors = new ArrayList<PVector>();
    PVector h = new PVector(0,0,0);
    float A = 0;
    for(int i=0; i<nV; i++) {
      //if(!boundaryVertices.contains(i)){
      h.set(0,0,0);
      niebors = new ArrayList<PVector>();
      int nA = 0;
      for(int j=0; j<nV; j++) {
        if (adjacency[i][j] == true) {
          nA++;
          niebors.add(positions.get(j));
          h.add(positions.get(j));
        }
      }
      h.div(nA);
      A = 0;
      PVector Pi = niebors.get(0);
      for(int j=1; j<nA-1; j++) {
        PVector Pj = niebors.get(j);
        PVector Pjp1 = niebors.get(j+1);
        //area of triangle Pi - Pj - Pjp1 = (1/2) * ||Pi-Pj X Pj-Pjp1||
        PVector tempA = PVector.sub(Pj,Pi).cross(PVector.sub(Pjp1,Pj));
        A += 0.5*(tempA.mag());

      }
      h.div(A);
      hf.add(h.copy());
    //}
    }
    for(int i=0; i<nV; i++) {
      //if(!boundaryVertices.contains(i))
      positions.get(i).add(hf.get(i).mult(tau));
    }
  }

  void volumeConservationFlow() {

  //gradient = chaque points : 1/6 somme des det des faces *** det qui peux étre reduit a q*r

  ArrayList<PVector> gradient = new ArrayList<PVector>();

  ArrayList<PVector> resFlow = new ArrayList<PVector>();

  ArrayList<PVector> actuV;
  PVector bariCentre;
  float multVal = 0;
  float carreGradient = 0;

  for(int i = 0; i < S.positions.size();i++) {

    if(!boundaryVertices.contains(i)){
    //gradient

    PVector detP = new PVector();
    for(int f = 0; f < S.nF;f++) {
      if(S.incidenceVF[i][f]) {
        Face ff = S.faces.get(f);

        int index = 0;

        // get index of point i in face ff
        for(int fff = 0; fff < ff.vertices.size();fff++) {
          if(ff.vertices.get(fff) == i) {
            index = fff;
            break;
          }
        }
        /*
          println("liste = " + ff.vertices);
          println("index = " + index);*/


        for(int p = 1; p < ff.vertices.size()-1;p++) {
          PVector p1 = S.positions.get(ff.vertices.get((index+p) % ff.vertices.size()));
          PVector p2 = S.positions.get(ff.vertices.get((index+p+1) % ff.vertices.size()));
          detP.add(p1.cross(p2)); // pas divisé par 6 (car pas utile)
          /*
          println("p1 = " + p1);
          println("p2 = " + p2);
          println("detP = " + detP);
          */
        }
      }
    }
    gradient.add(detP);

    // valeur pour renormalization
    carreGradient += detP.x * detP.x + detP.y * detP.y + detP.z * detP.z;



    //////////FLOW

    // sum of all adjacent points
    actuV = new ArrayList<PVector>();
    for(int j = 0; j < S.positions.size();j++) {
       if(S.adjacency[i][j]) {
         actuV.add(S.positions.get(j));
       }
    }

    bariCentre = new PVector();

    for(int j = 0; j < actuV.size();j++) {
      bariCentre.add(actuV.get(j));
    }

    bariCentre.div(actuV.size());
    bariCentre.sub(S.positions.get(i));
    bariCentre.mult(tau);

    resFlow.add(bariCentre);

    // renormalization
    multVal += bariCentre.x * detP.x + bariCentre.y * detP.y + bariCentre.z * detP.z;

  }
  }




  multVal = multVal / carreGradient;


    println("gradient : " + gradient);
    println("\n\n");
    println("resFlow : " + resFlow);

    println("multVal : " + multVal);
    println("carreGradient : " + carreGradient);

    println("flow : " + resFlow);

  for(int i = 0; i < S.positions.size();i++) {
    resFlow.get(i).sub(gradient.get(i).mult(multVal));
  }

  for(int i = 0; i < S.positions.size();i++) {
    S.positions.get(i).add(resFlow.get(i));
  }


}
    //void volumeConservationFlow(float tau) {
  //  PVector[] hf = new PVector[nV];
  //  PVector h = new PVector(0,0,0);
  //  PVector[] gradient = gradient();
  //  float dot = 0;
  //  float norm = 0;
  //  for(int i=0; i<nV; i++) {
  //    if(!boundaryVertices.contains(i)){
  //    h.set(0,0,0);
  //    int nA = 0;
  //    for(int j=0; j<nV; j++) {
  //      if (adjacency[i][j] == true) {
  //        nA++;
  //        h.add(positions.get(j));
  //      }
  //    }
  //    h.div(nA);
  //    hf[i] = h.copy();
  //    //println(hf[i]);
  //    //println(gradient[i]);
  //    dot += hf[i].dot(gradient[i]);
  //    norm += gradient[i].dot(gradient[i]);
  //  }

  //  }
  //  //println(dot);
  //  //println(norm);
  //  for (int i=0; i<nV; i++) {
  //    if(!boundaryVertices.contains(i)){
  //    hf[i].sub(gradient[i].mult(dot/norm));
  //    positions.get(i).add(hf[i].mult(tau));
  //    }
  //    //println(hf[i]);
  //  }
  //  for (int j=0; j<this.nV; j++) {
  //    for (int k=j+1; k<this.nV; k++) {
  //      if (adjacency[j][k]) {
  //        PVector c = this.positions.get(j).cross(this.positions.get(k));
  //        this.edgeCross[j][k] = c.copy();
  //        this.edgeCross[k][j] = c.mult(-1).copy();
  //      }
  //    }
  //  }
  //}

  PVector[] meanCurvatureFlow() {
    PVector[] mcf = new PVector[nV];
    // Q is the point we calculate the mcf for in each iteration
    // P[i] is the successor of Q on face j, and the shared vertex of faces (j, j+1)
    // P[i-1] is the predecessor of Q on face j
    // P[i+i] is the successor of Q on face (j+1)
    // Mi is the edge (P[i], Q)
    PVector q, pim1, pi, pip1, Mi;
    int prevIdxPrevFace=-1, nextIdxPrevFace=-1, prevIdxCurrFace=-1, nextIdxCurrFace = -1;
    int firstFace=-1, prevFace=-1, currFace=-1;
    Face face;
    int degree;
    int idx;
    int f;
    // angleBefore is the angle (Q, P[i-1], P[i])
    // angleAfter is the angle (Q, P[i+1], P[i])
    // A[i] = cotan(angleBefore) + cotan(angleAfter)
    float angleBefore, angleAfter, Ai, starQ;
    PVector e1, e2;
    boolean found, cycle;
    for (int i=0; i<nV; i++) {
      q = positions.get(i);
      starQ = 0;
      // initialize its mcf to 0
      mcf[i] = new PVector(0,0,0);
      //find a face containing point Q
      firstFace = 0;
      found = false;
      f = 0;
      while (!found) {
        if (incidenceVF[i][f]) {
          found = true;
          face = faces.get(f);
          degree = face.vertices.size();
          // index of Q in the face
          idx = face.vertices.indexOf(i);
          if (idx == 0)
            prevIdxCurrFace = degree-1;
          else
            prevIdxCurrFace = idx-1;
          prevIdxCurrFace = face.vertices.get(prevIdxCurrFace);
          nextIdxCurrFace = face.vertices.get((idx+1)%degree);
          firstFace = f;
          prevFace = f;
        } else {
          f++;
        }
      }

      currFace = -1;
      // have we ended up on the initial face, closing the loop?
      cycle = false;
      // cycle over all faces containing point Q in the right order
      // (using the information about the next point in the current face
      // to find the face they share)
      while (!cycle) {
        f = 0;
        found = false;
        // find the other shared face between Q and its successor
        while (!found) {
          if (incidenceVF[i][f] && incidenceVF[nextIdxCurrFace][f] && f!=prevFace) {
            found = true;
            face = faces.get(f);
            degree = face.vertices.size();
            idx = face.vertices.indexOf(i);
            // update previous/current relations
            currFace = f;
            prevIdxPrevFace = prevIdxCurrFace;
            nextIdxPrevFace = nextIdxCurrFace;
            // possible error source, but should be always verified:
            // prevIdxCurrFace = nextIdxPrevFace;
            if (idx == 0)
              prevIdxCurrFace = degree-1;
            else
              prevIdxCurrFace = idx-1;
            prevIdxCurrFace = face.vertices.get(prevIdxCurrFace);
            nextIdxCurrFace = face.vertices.get((idx+1)%degree);
          }
          else {
            f++;
          }
        }
        // at this point we have found the next face and update every other vertex
        pim1 = positions.get(prevIdxPrevFace);
        pi = positions.get(nextIdxPrevFace);
        pip1 = positions.get(nextIdxCurrFace);
        //area of triangle Pi - Pj - Pjp1 = (1/2) * ||Pi-Pj X Pj-Pjp1||
        // PVector tempA = PVector.sub(q,pim1).cross(PVector.sub(pi,q));
        // starQ += 0.5*tempA.mag();
        Mi = PVector.sub(q,pi);
        angleBefore = PVector.angleBetween(PVector.sub(pim1,q), PVector.sub(pi,pim1));
        // e1 = PVector.sub(pim1,q);
        // e2 = PVector.sub(pi,pim1);
        // angleBefore = acos((e1.dot(e2))/(e1.mag()*e2.mag()));
        angleAfter = PVector.angleBetween(PVector.sub(pip1,pi), PVector.sub(q,pip1));
        // e1 = PVector.sub(pip1,pi);
        // e2 = PVector.sub(q,pip1);
        // angleAfter = acos((e1.dot(e2))/(e1.mag()*e2.mag()));
        Ai = 1/tan(angleBefore) + 1/tan(angleAfter);
        Mi.mult(Ai/2);
        // Mi.mult(Ai/(2*starQ));
        mcf[i].add(Mi);

        prevFace = currFace;
        // check if we the face we just visited is also the one we started with
        // (in this case, job done)
        if (currFace == firstFace)
          cycle = true;
      }
    }

    return mcf;

  }

  void meanCurvatureFlowVolConstr(float tau) {
    PVector[] mcf = new PVector[nV];
    PVector[] gradient = new PVector[nV];
    float gradientNorm = 0;
    float multVal = 0;
    // Q is the point we calculate the mcf for in each iteration
    // P[i] is the successor of Q on face j, and the shared vertex of faces (j, j+1)
    // P[i-1] is the predecessor of Q on face j
    // P[i+i] is the successor of Q on face (j+1)
    // Mi is the edge (P[i], Q)
    PVector q, pim1, pi, pip1, Mi;
    int prevIdxPrevFace=-1, nextIdxPrevFace=-1, prevIdxCurrFace=-1, nextIdxCurrFace = -1;
    int firstFace=-1, prevFace=-1, currFace=-1;
    Face face;
    int degree;
    int idx;
    int f;
    // angleBefore is the angle (Q, P[i-1], P[i])
    // angleAfter is the angle (Q, P[i+1], P[i])
    // A[i] = cotan(angleBefore) + cotan(angleAfter)
    float angleBefore, angleAfter, Ai;
    PVector e1, e2;
    boolean found, cycle;
    for (int i=0; i<nV; i++) {
      PVector detP = new PVector(0,0,0);
      q = positions.get(i);
      // initialize its mcf to 0
      mcf[i] = new PVector(0,0,0);
      //find a face containing point Q
      firstFace = 0;
      found = false;
      f = 0;
      while (!found) {
        if (incidenceVF[i][f]) {
          found = true;
          face = faces.get(f);
          degree = face.vertices.size();
          // index of Q in the face
          idx = face.vertices.indexOf(i);
          if (idx == 0)
            prevIdxCurrFace = degree-1;
          else
            prevIdxCurrFace = idx-1;
          prevIdxCurrFace = face.vertices.get(prevIdxCurrFace);
          nextIdxCurrFace = face.vertices.get((idx+1)%degree);
          firstFace = f;
          prevFace = f;

          // gradient
          for(int p=1; p<degree-1; p++) {
            PVector p1 = S.positions.get(face.vertices.get((idx+p) % degree));
            PVector p2 = S.positions.get(face.vertices.get((idx+p+1) % degree));
            detP.add(p1.cross(p2)); // pas divisé par 6 (car pas utile)
            //println("while 1");
          }
        } else {
          f++;
        }
      }

      currFace = -1;
      // have we ended up on the initial face, closing the loop?
      cycle = false;
      // cycle over all faces containing point Q in the right order
      // (using the information about the next point in the current face
      // to find the face they share)
      while (!cycle) {
        f = 0;
        found = false;
        // find the other shared face between Q and its successor
        while (!found) {
          if (incidenceVF[i][f] && incidenceVF[nextIdxCurrFace][f] && f!=prevFace) {
            found = true;
            face = faces.get(f);
            degree = face.vertices.size();
            idx = face.vertices.indexOf(i);
            // update previous/current relations
            currFace = f;
            prevIdxPrevFace = prevIdxCurrFace;
            nextIdxPrevFace = nextIdxCurrFace;
            // possible error source, but should be always verified:
            // prevIdxCurrFace = nextIdxPrevFace;
            if (idx == 0)
              prevIdxCurrFace = degree-1;
            else
              prevIdxCurrFace = idx-1;
            prevIdxCurrFace = face.vertices.get(prevIdxCurrFace);
            nextIdxCurrFace = face.vertices.get((idx+1)%degree);
            // gradient
            for(int p = 1; p < degree-1;p++) {
              PVector p1 = S.positions.get(face.vertices.get((idx+p) % degree));
              PVector p2 = S.positions.get(face.vertices.get((idx+p+1) % degree));
              detP.add(p1.cross(p2)); // pas divisé par 6 (car pas utile)
              //println("while 2");
            }
          }
          else {
            f++;
          }
        }
        // at this point we have found the next face and update every other vertex
        pim1 = positions.get(prevIdxPrevFace);
        pi = positions.get(nextIdxPrevFace);
        pip1 = positions.get(nextIdxCurrFace);
        Mi = PVector.sub(q,pi);
        angleBefore = PVector.angleBetween(PVector.sub(pim1,q), PVector.sub(pi,pim1));
        // e1 = PVector.sub(pim1,q);
        // e2 = PVector.sub(pi,pim1);
        // angleBefore = acos((e1.dot(e2))/(e1.mag()*e2.mag()));
        angleAfter = PVector.angleBetween(PVector.sub(pip1,pi), PVector.sub(q,pip1));
        // e1 = PVector.sub(pip1,pi);
        // e2 = PVector.sub(q,pip1);
        // angleAfter = acos((e1.dot(e2))/(e1.mag()*e2.mag()));
        Ai = 1/tan(angleBefore) + 1/tan(angleAfter);
        Mi.mult(Ai/2);
        mcf[i].add(Mi);

        prevFace = currFace;
        // check if we the face we just visited is also the one we started with
        // (in this case, job done)
        if (currFace == firstFace)
          cycle = true;
      }
      gradient[i] = detP;
      gradientNorm += detP.x * detP.x + detP.y * detP.y + detP.z * detP.z;
      multVal += mcf[i].x * detP.x + mcf[i].y * detP.y + mcf[i].z * detP.z;

      // println("point: " + i);
      // println("gradientNorm: " + gradientNorm);
      // println("multVal: " + multVal);
    }

    multVal = multVal/gradientNorm;
    for(int i=0; i < nV; i++) {
      mcf[i].sub(gradient[i].mult(multVal));
    }

    for(int i=0; i<nV; i++) {
      positions.get(i).add(mcf[i].mult(tau));
    }

    println(volume());

  }


void squarMeanCurvatureFlow(float tau) {
    PVector[] smcf = new PVector[nV];
    PVector[] mcf = new PVector[nV];
    PVector q, pim1, pi, pip1, Mi;
    int prevIdxPrevFace=-1, nextIdxPrevFace=-1, prevIdxCurrFace=-1, nextIdxCurrFace = -1;
    int firstFace=-1, prevFace=-1, currFace=-1;
    Face face;
    int degree;
    int idx;
    int f;
    float angleBefore, angleAfter, Ai;
    boolean found, cycle;
    //int neighbor = -1;
    for (int i=0; i<nV; i++) {
      mcf[i] = new PVector(0,0,0);
      q = positions.get(i);
      //if(!boundaryVertices.contains(i)){

      //find a face of Pi
      firstFace = 0;
      found = false;
      f = 0;
      while (!found) {
        if (incidenceVF[i][f]) {
          found = true;
          face = faces.get(f);
          degree = face.vertices.size();
          idx = face.vertices.indexOf(i);
          nextIdxCurrFace = face.vertices.get((idx+1)%degree);
          if (idx == 0)
            prevIdxCurrFace = degree-1;
          else
            prevIdxCurrFace = idx-1;
          firstFace = f;
          prevFace = f;
        } else {
          f++;
        }
      }

      currFace = -1;
      cycle = false;
      // cycle over all faces of P[i] in the right order
      // using the information about the next point in the current face
      while (!cycle) {
        f = 0;
        found = false;
        // find the shared face between P[i] and its successor
        while (!found) {
          if (incidenceVF[i][f] && incidenceVF[nextIdxCurrFace][f] && f!=prevFace) {
            found = true;
            face = faces.get(f);
            degree = face.vertices.size();
            idx = face.vertices.indexOf(i);
            prevIdxPrevFace = prevIdxCurrFace;
            nextIdxPrevFace = nextIdxCurrFace;
            prevIdxCurrFace = nextIdxPrevFace;
            nextIdxCurrFace = face.vertices.get((idx+1)%degree);
          }
          else {
            f++;
          }
        }
        // we have found the next face
        pim1 = positions.get(prevIdxPrevFace);
        pi = positions.get(nextIdxPrevFace);
        pip1 = positions.get(nextIdxCurrFace);
        Mi = PVector.sub(q,pi);
        angleBefore = PVector.angleBetween(PVector.sub(pim1,q), PVector.sub(pi,pim1));
        //println(angleBefore);
        if (angleBefore < -PI)
          angleBefore += 2*PI;
        else if (angleBefore > PI)
          angleBefore -= 2*PI;
        angleAfter = PVector.angleBetween(PVector.sub(pip1,pi), PVector.sub(q,pip1));
        if (angleAfter < -PI)
          angleAfter += 2*PI;
        else if (angleAfter > PI)
          angleAfter -= 2*PI;
        Ai = 1/tan(angleBefore) + 1/tan(angleAfter);
        //println(Ai);
        Mi.mult(Ai);
        mcf[i].sub(Mi);

        // before looking for a new face
        prevFace = currFace;
        prevIdxPrevFace = prevIdxCurrFace;
        nextIdxPrevFace = nextIdxCurrFace;
        if (currFace == firstFace)
          cycle = true;
      }
    }
    for(int i=0; i<nV; i++) {
      float a = mcf[i].mag();
      smcf[i]= mcf[i].mult(a);
    }
    for(int i=0; i<nV; i++) {
      positions.get(i).add(smcf[i].mult(tau));
    }
  }
}
