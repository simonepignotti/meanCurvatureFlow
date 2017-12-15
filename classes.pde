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
  ArrayList<Integer> boundVertex = new ArrayList<Integer>();
  ArrayList<Face> faces = new ArrayList<Face>();
  boolean[][] incidenceVF = new boolean[nVmax][nFmax]; // true iff v is in f 
  boolean[][] adjacency = new boolean[nVmax][nVmax]; // true iff v1 ~ v2 


  void drawSurface() {
    int i;
    for (i=0; i<this.nF; i++) {
      drawFace(this, i, 250, 137);
    }
    /*for(i=0; i< this.nV; i++) {
     pushMatrix();
     println(positions.get(i).x,positions.get(i).y,positions.get(i).z);
     translate(positions.get(i).x,positions.get(i).y,positions.get(i).z);
     sphere(10);
     popMatrix();
     }*/
  }

  Surface(String filename) {
    String[] lines = loadStrings(filename);  // in data folder
  
    /* // sample PLY file for testing
    String[] lines = {"ply", "element vertex 8", "element face 6","end_header",
    "-1 -1 -1",
    "1 -1 -1",
    "1 1 -1",
    "-1 1 -1 ",
    "-1 -1 1 ",
    "1 -1 1 ",
    "1 1 1 ",
    "-1 1 1",
    "4 0 1 2 3", 
    "4 5 4 7 6 ",
    "4 6 2 1 5 ",
    "4 3 7 4 0 ",
    "4 7 3 2 6 ",
    "4 5 1 0 4 "
    };
    */
    
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
      }
    }
  }
}