/* class containing the data of a window:
- the associated surface;
- the menu buttons;
- the kind of flow to apply;
- the axis rotation;
- the initial volume of the surface (before applying any flow)
- the tau to use for this window
*/
class MyWinData extends GWinData {
    Surface S;
    GButton menuB;
    int flow; //negative = pause
    int rotaX = 0;
    int rotaY = 0;
    float initialVol = 0;
    float tau = 0.005;
}

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

  void drawSurface(PApplet graph) {

    for (int i=0; i<this.nF; i++) {
      drawFace(this, i, 250, 137, graph);
    }

  }


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

    // add all boundary vertices to an array to speed up boundary checks
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

  // returns the gradient of each vertex
  PVector[] gradient() {

    PVector[] grad = new PVector[nV];
    Face face;
    PVector p1, p2, g;
    // degree of the face and index of P_i in f
    int degree, idx;

    // for every vertex P_i
    for(int i=0; i<nV; i++) {

      g = new PVector(0,0,0);

      // for every face containing P_i
      for (int f=0; f<this.nF; f++) {
        if(this.incidenceVF[i][f]) {
          face = this.faces.get(f);
          idx = face.vertices.indexOf(i);
          degree = face.vertices.size();

          // add the cross product of every two consecutive vertices in F (divided by 6)
          for(int j=1; j<degree-1; j++) {
            p1 = this.positions.get(face.vertices.get((idx+j) % degree));
            p2 = this.positions.get(face.vertices.get((idx+j+1) % degree));
            g.add(p1.cross(p2).div(6));
          }
        }
      }
      grad[i] = g;
    }
    return grad;
  }

  // harmonic flow (see report for details)
  PVector[] harmonicFlow() {
    PVector[] hf = new PVector[nV];
    PVector h = new PVector(0,0,0);
    // number of neighbours
    int n = 0;

    for (int i=0; i<nV; i++) {
      if (!boundaryVertices.contains(i)) {
        h.set(0,0,0);
        n = 0;
        for(int j=0; j<nV; j++) {
          if (adjacency[i][j]) {
            n++;
            h.add(positions.get(j));
          }
        }
        h.div(n);
        hf[i] = h.copy();
      }
      else {
        hf[i] = new PVector(0,0,0);
      }
    }
    return hf;
  }

  // harmonic flow divided by the area
  PVector[] harmonicAreaFlow() {
    PVector[] hf = new PVector[nV];
    PVector h = new PVector(0,0,0);
    ArrayList<PVector> neighbours;
    // value of the area
    float A = 0;
    // number of neighbours
    int nA;
    PVector Pi, Pj, Pjp1, tempA;

    // for every vertex P_i
    for(int i=0; i<nV; i++) {
      if(!boundaryVertices.contains(i)) {
        h.set(0,0,0);
        neighbours = new ArrayList<PVector>();
        nA = 0;
        // compute the harmonic flow and store the neighbours
        for(int j=0; j<nV; j++) {
          if (adjacency[i][j]) {
            nA++;
            neighbours.add(positions.get(j));
            h.add(positions.get(j));
          }
        }
        h.div(nA);
        A = 0;
        Pi = neighbours.get(0);
        for(int j=1; j<nA-1; j++) {
          Pj = neighbours.get(j);
          Pjp1 = neighbours.get(j+1);
          //area of triangle Pi - Pj - Pjp1 = (1/2) * ||Pi-Pj X Pj-Pjp1||
          tempA = PVector.sub(Pj,Pi).cross(PVector.sub(Pjp1,Pj));
          A += 0.5*(tempA.mag());

        }
        h.div(A);
        hf[i] = h.copy();
      }
      else {
        hf[i] = new PVector(0,0,0);
      }
    }

    return hf;
  }

  PVector[] meanCurvatureFlow() {
    PVector[] mcf = new PVector[nV];
    // Q is the point we calculate the mcf for in each iteration
    // P[i] is the predecessor of Q on face j, the successor of Q on face (j+1),
    //      and therefore the shared vertex of faces (j, j+1)
    // P[i-1] is the successor of Q on face j
    // P[i+i] is the predecessor of Q on face (j+1)
    // Mi is the edge (P[i], Q)
    PVector q, pim1, pi, pip1, Mi, qpi, qpip1, N;
    int prevIdxPrevFace=-1, nextIdxPrevFace=-1, prevIdxCurrFace=-1, nextIdxCurrFace = -1;
    int firstFace=-1, prevFace=-1, currFace=-1;
    Face face;
    int degree;
    int idx;
    int f;
    boolean found, cycle;

    for (int i=0; i<nV; i++) {
      if (!boundaryVertices.contains(i)) {
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
          } else {
            f++;
          }
        }

        currFace = -1;
        // have we ended up on the initial face, closing the loop?
        cycle = false;
        // cycle over all faces containing point Q in the right order
        // (using the information about the previous point in the current face
        // to find the face they share)
        while (!cycle) {
          f = 0;
          found = false;
          // find the other shared face between Q and its predecessor
          while (!found) {
            if (incidenceVF[i][f] && incidenceVF[prevIdxCurrFace][f] && f!=prevFace) {
              found = true;
              face = faces.get(f);
              degree = face.vertices.size();
              idx = face.vertices.indexOf(i);
              // update previous/current relations
              currFace = f;
              prevIdxPrevFace = prevIdxCurrFace;
              nextIdxPrevFace = nextIdxCurrFace;
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
          pim1 = positions.get(nextIdxPrevFace);
          pi = positions.get(prevIdxPrevFace);
          pip1 = positions.get(prevIdxCurrFace);
          Mi = PVector.sub(pip1,pi);
          qpi = PVector.sub(pi,q);
          qpip1 = PVector.sub(pip1,q);
          N = qpi.cross(qpip1);
          N.div(N.mag());
          Mi = N.cross(Mi).mult(-0.5);

          boolean infiniteComp = false;
          if (pInfiniteFloat.isInfinite(Mi.x) || pInfiniteFloat.isInfinite(Mi.y) || pInfiniteFloat.isInfinite(Mi.z)) {
            println("WARNING: INFINITE COMPONENT ON POINT " + i);
            infiniteComp = true;
          }

          if (pInfiniteFloat.isNaN(Mi.x) || pInfiniteFloat.isNaN(Mi.y) || pInfiniteFloat.isNaN(Mi.z)) {
            println("WARNING: NaN COMPONENT ON POINT " + i);
            infiniteComp = true;
          }

          if (!infiniteComp) {
            if (abs(Mi.x) > maxFlowComp) {
              float ratioComp = maxFlowComp/abs(Mi.x);
              Mi.mult(ratioComp);
              // Mi.set(maxFlowComp*Math.signum(Mi.x),Mi.y,Mi.z);
            }
            if (abs(Mi.y) > maxFlowComp) {
              float ratioComp = maxFlowComp/abs(Mi.y);
              Mi.mult(ratioComp);
              // Mi.set(Mi.x,maxFlowComp*Math.signum(Mi.y),Mi.z);
            }
            if (abs(Mi.z) > maxFlowComp) {
              float ratioComp = maxFlowComp/abs(Mi.z);
              Mi.mult(ratioComp);
              // Mi.set(Mi.x,Mi.y,maxFlowComp*Math.signum(Mi.z));
            }

            mcf[i].add(Mi);
          }

          prevFace = currFace;
          // check if we the face we just visited is also the one we started with
          // (in this case, job done)
          if (currFace == firstFace)
            cycle = true;
        }
      }
      else {
        mcf[i] = new PVector(0,0,0);
      }
    }

    return mcf;

  }

  PVector[] meanCurvatureFlowCotan() {
    PVector[] mcf = new PVector[nV];
    // Q is the point we calculate the mcf for in each iteration
    // P[i] is the predecessor of Q on face j, the successor of Q on face (j+1),
    //      and therefore the shared vertex of faces (j, j+1)
    // P[i-1] is the successor of Q on face j
    // P[i+i] is the predecessor of Q on face (j+1)
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
    boolean found, cycle;
    for (int i=0; i<nV; i++) {
      if(!boundaryVertices.contains(i)) {
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
          } else {
            f++;
          }
        }

        currFace = -1;
        // have we ended up on the initial face, closing the loop?
        cycle = false;
        // cycle over all faces containing point Q in the right order
        // (using the information about the previous point in the current face
        // to find the face they share)
        while (!cycle) {
          f = 0;
          found = false;
          // find the other shared face between Q and its predecessor
          while (!found) {
            if (incidenceVF[i][f] && incidenceVF[prevIdxCurrFace][f] && f!=prevFace) {
              found = true;
              face = faces.get(f);
              degree = face.vertices.size();
              idx = face.vertices.indexOf(i);
              // update previous/current relations
              currFace = f;
              prevIdxPrevFace = prevIdxCurrFace;
              nextIdxPrevFace = nextIdxCurrFace;
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
          pim1 = positions.get(nextIdxPrevFace);
          pi = positions.get(prevIdxPrevFace);
          pip1 = positions.get(prevIdxCurrFace);
          Mi = PVector.sub(q,pi);
          angleBefore = PVector.angleBetween(PVector.sub(pim1,q), PVector.sub(pi,pim1));
          angleAfter = PVector.angleBetween(PVector.sub(pip1,pi), PVector.sub(q,pip1));

          Ai = 1/tan(angleBefore) + 1/tan(angleAfter);
          Mi.mult(Ai/2);
          // Mi.mult(Ai/(2*starQ));
          if (angleBefore > PI-0.0001 || angleBefore < 0.0001 || angleAfter > PI-0.0001 || angleAfter < 0.0001) {
            println("point: " + i);
            println("angleBefore: " + angleBefore);
            println("angleAfter: " + angleAfter);
            println("flowContribution: " + Mi);
          }

          boolean infiniteComp = false;
          if (pInfiniteFloat.isInfinite(Mi.x) || pInfiniteFloat.isInfinite(Mi.y) || pInfiniteFloat.isInfinite(Mi.z)) {
            println("WARNING: INFINITE COMPONENT ON POINT " + i);
            infiniteComp = true;
          }

          if (pInfiniteFloat.isNaN(Mi.x) || pInfiniteFloat.isNaN(Mi.y) || pInfiniteFloat.isNaN(Mi.z)) {
            println("WARNING: NaN COMPONENT ON POINT " + i);
            infiniteComp = true;
          }

          if (!infiniteComp) {
            if (abs(Mi.x) > maxFlowComp) {
              float ratioComp = maxFlowComp/abs(Mi.x);
              Mi.mult(ratioComp);
              // Mi.set(maxFlowComp*Math.signum(Mi.x),Mi.y,Mi.z);
            }
            if (abs(Mi.y) > maxFlowComp) {
              float ratioComp = maxFlowComp/abs(Mi.y);
              Mi.mult(ratioComp);
              // Mi.set(Mi.x,maxFlowComp*Math.signum(Mi.y),Mi.z);
            }
            if (abs(Mi.z) > maxFlowComp) {
              float ratioComp = maxFlowComp/abs(Mi.z);
              Mi.mult(ratioComp);
              // Mi.set(Mi.x,Mi.y,maxFlowComp*Math.signum(Mi.z));
            }

            mcf[i].add(Mi);
          }

          prevFace = currFace;
          // check if we the face we just visited is also the one we started with
          // (in this case, job done)
          if (currFace == firstFace)
            cycle = true;
        }
      }
      else {
        mcf[i] = new PVector(0,0,0);
      }
    }

    return mcf;

  }

  PVector[] squaredMeanCurvatureFlow() {
    PVector[] smcf = meanCurvatureFlow();

    for(int i=0; i<nV; i++) {
      smcf[i] = smcf[i].mult(smcf[i].mag());
    }

    return smcf;

  }

}
