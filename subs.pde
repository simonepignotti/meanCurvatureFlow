



void homotecieOnS(float scale) {  // for zooming in and out
    for (int i = 0; i < S.positions.size(); i++) {
      S.positions.get(i).mult(scale);
    }
}






float volumeOfS() {
  float det = 0; 
    for (int i = 0; i < S.faces.size(); i++) {
        Face f = S.faces.get(i);
        for (int j = 0; j+2 < f.vertices.size(); j++) {
            PVector v1 = S.positions.get(f.vertices.get(0));
            PVector v2 = S.positions.get(f.vertices.get(1+j));
            PVector v3 = S.positions.get(f.vertices.get(2+j));
            det += v1.cross(v2).dot(v3);
        }
    }
    return det/6;
}

void flowHarmonique() {
  
  ArrayList<PVector> resFlow = new ArrayList<PVector>();

  ArrayList<PVector> actuV;
  PVector bariCentre;
    
  for(int i = 0; i < S.positions.size();i++) {

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
    bariCentre.x /=  actuV.size();
    bariCentre.y /=  actuV.size();
    bariCentre.z /=  actuV.size();
    
    bariCentre.sub(S.positions.get(i));
    
    bariCentre.x *= tau;
    bariCentre.y *= tau;
    bariCentre.z *= tau;
    
    bariCentre.add(S.positions.get(i));
    
    resFlow.add(bariCentre);
    
  }

  for(int i = 0; i < S.positions.size();i++) {
    S.positions.set(i,resFlow.get(i));
  }

}


ArrayList<Integer> pointsDansOrdre(int p) {
  ArrayList<Integer> pps = new ArrayList<Integer>();
  ArrayList<Integer> fs = new ArrayList<Integer>();
  boolean k = false;
  
  for(int f = 0; f < S.faces.size();f++) {
      if(S.incidenceVF[p][f]) {
        Face ff = S.faces.get(f);
        if(k) {
          fs.add(f); // prendre faces incidente
        } else {
          for(int i = 0; i < ff.vertices.size();i++) { // Deux premier point
              if(ff.vertices.get(i) == p) {
                pps.add(ff.vertices.get((i+1 ) % ff.vertices.size()));
                pps.add(ff.vertices.get((ff.vertices.size() + i-1) % ff.vertices.size()));
                break;
              }
          }
          k = true;
        }
      }
  }
  
  int fi = 0;
  while(fs.size() > 0) { // prendre reste point a partir des faces incidentes
    if(S.incidenceVF[pps.get(pps.size()-1)][fs.get(fi)]) {
        Face ff = S.faces.get(fs.get(fi));
        for(int i = 0; i < ff.vertices.size();i++) {
            if(ff.vertices.get(i) == p) {
              pps.add(ff.vertices.get((ff.vertices.size() + i-1) % ff.vertices.size()));
              break;
            }
        }
      fs.remove(fi);
      fi = 0;
      continue;
    }
    fi++;
  }
  pps.remove(pps.size()-1);
  return pps;
}


void flowHarmoniqueContrain() {  
  
  //gradient = chaque points : 1/6 somme des det des faces *** det qui peux étre reduit a q*r 
  
  ArrayList<PVector> gradient = new ArrayList<PVector>();
  
  ArrayList<PVector> resFlow = new ArrayList<PVector>();

  ArrayList<PVector> actuV;
  PVector bariCentre;
  float multVal = 0;
  float carreGradient = 0;
    
  for(int i = 0; i < S.positions.size();i++) {
    
    //gradient
    
    PVector detP = new PVector();
    for(int f = 0; f < S.nF;f++) {
      if(S.incidenceVF[i][f]) {
        Face ff = S.faces.get(f);
        
        int index = 0;
        
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
          PVector p1 = S.positions.get(ff.vertices.get((p+index) % ff.vertices.size()));
          PVector p2 = S.positions.get(ff.vertices.get((p+index+1) % ff.vertices.size()));
          detP = PVector.add(detP,p1.cross(p2)); // pas divisé par 6 (car pas utile)
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
    
    bariCentre.x /=  actuV.size();
    bariCentre.y /=  actuV.size();
    bariCentre.z /=  actuV.size();
    
    bariCentre.sub(S.positions.get(i));
    
    bariCentre.x *= tau;
    bariCentre.y *= tau;
    bariCentre.z *= tau;
    
    
    resFlow.add(bariCentre);
    
    // valeur pour renormalization
    multVal += bariCentre.x * detP.x + bariCentre.y * detP.y + bariCentre.z * detP.z;
    
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



void flowMoyenneContrain() {  
  
  //gradient = chaque points : 1/6 somme des det des faces *** det qui peux étre reduit a q*r 
  
  ArrayList<PVector> gradient = new ArrayList<PVector>();
  
  ArrayList<PVector> resFlow = new ArrayList<PVector>();

  ArrayList<PVector> actuV;
  PVector bariCentre;
  float multVal = 0;
  float carreGradient = 0;
    
  for(int i = 0; i < S.positions.size();i++) {
    
    //gradient
    
    PVector detP = new PVector();
    for(int f = 0; f < S.nF;f++) {
      if(S.incidenceVF[i][f]) {
        Face ff = S.faces.get(f);
        
        int index = 0;
        
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
          PVector p1 = S.positions.get(ff.vertices.get((p+index) % ff.vertices.size()));
          PVector p2 = S.positions.get(ff.vertices.get((p+index+1) % ff.vertices.size()));
          detP = PVector.add(detP,p1.cross(p2)); // pas divisé par 6 (car pas utile)
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
    
    bariCentre.x /=  actuV.size();
    bariCentre.y /=  actuV.size();
    bariCentre.z /=  actuV.size();
    
    bariCentre.sub(S.positions.get(i));
    
    bariCentre.x *= tau;
    bariCentre.y *= tau;
    bariCentre.z *= tau;
    
    
    resFlow.add(bariCentre);
    
    // valeur pour renormalization
    multVal += bariCentre.x * detP.x + bariCentre.y * detP.y + bariCentre.z * detP.z;
    
  }
  
  multVal = multVal / carreGradient;
  

  for(int i = 0; i < S.positions.size();i++) {
    resFlow.get(i).sub(gradient.get(i).mult(multVal));
  }

  for(int i = 0; i < S.positions.size();i++) {
    S.positions.get(i).add(resFlow.get(i));
  }
  

}