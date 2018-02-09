int nVmax = 2000;
int nEmax = 2000;
int nFmax = 3500;
float distance = 2;  // for camera
float tau = 0.1;
float volBefore;
float volAfter;
boolean first = true;
Surface S;
float initialVol = 0;
int its = 0;

void setup() {
  size(1500, 1500, P3D);
  S = new Surface("icosphereBB.txt");
  initialVol = S.volume();
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

  S.drawSurface();
  PVector[] mcf = S.meanCurvatureFlow();
  S.applyFlowRenorm(mcf, initialVol, tau);
}

void mouseWheel(MouseEvent event) {  // for zooming in and out
  float e = event.getCount();
  distance += e/100;
}
