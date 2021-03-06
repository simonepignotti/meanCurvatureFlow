import g4p_controls.*;

// maximum number of vertices, edges and faces
int nVmax = 2000;
int nEmax = 2000;
int nFmax = 3500;

// maximum number of open windows
int maxS = 6;

// values to bound the flows
float maxFlowComp = 100;
Float pInfiniteFloat = Float.POSITIVE_INFINITY;
Float nInfiniteFloat = Float.NEGATIVE_INFINITY;

// interface buttons and fields
GButton btnStart;
GButton btnFlow;

GButton editFlow;
GButton editActiveFlow;
GButton editTau;
GButton editSurface;
GButton endEdit;
GLabel flowName;


GTextField flowT;
GTextField tauT;

// bool to start/stop the flows on all windows
boolean flowing = false;

//tableau des fenetres
MyWinData surfaces[];
int nbS = 0;
int editing = -1;

void setup() {
  size(800, 300, P3D);
  surfaces = new MyWinData[maxS];
  btnStart = new GButton(this, 20, 30, 80, 80, "NEW");
  btnFlow = new GButton(this, 20, 150, 80, 80, "Start flow");

  editFlow = new GButton(this, 40, 30, 120, 90, "Flow type");
  editTau = new GButton(this, 250, 30, 120, 90, "Tau factor");

  editActiveFlow = new GButton(this, 40, 180,120, 90, "Active");
  editSurface = new GButton(this, 250, 180, 120, 90, "Surface File");
  endEdit = new GButton(this, 460, 180, 120, 90, "OK");

  flowT = new GTextField(this, 50, 140, 110, 24);
  tauT  = new GTextField(this, 260, 140, 110, 24);
  flowName = new GLabel(this, 40, 116, 500, 24);

  flowT.setPromptText("new flow value");
  tauT.setPromptText("new tau value");

  buttonsVisibility(true);
}

void draw() {
  background(130, 130, 130);
}

// change menu (by changing buttons visibility)
void buttonsVisibility(boolean menu) { // true => general // false => bouton
    // Menu general 
    btnStart.setVisible(menu);
    btnFlow.setVisible(menu);
    for(int i=0;i<nbS;i++) {
        surfaces[i].menuB.setVisible(menu);
    }

    // Menu bouton 
    editFlow.setVisible(!menu);
    editActiveFlow.setVisible(!menu);
    editTau.setVisible(!menu);
    editSurface.setVisible(!menu);
    endEdit.setVisible(!menu);
    
    flowName.setVisible(!menu);
    
    flowT.setVisible(!menu);
    tauT.setVisible(!menu);

    refreshFlowButtons();

}

// update button labels
void refreshFlowButtons() {
    if(editing >= 0) {
        if(surfaces[editing].flow > 0)
            editActiveFlow.setText("Active");
        else
            editActiveFlow.setText("Inactive");
        editFlow.setText("Flow type = " + surfaces[editing].flow);
        editTau.setText("Tau factor = " + surfaces[editing].tau);
        flowName.setText(nameFlow( surfaces[editing].flow));
    }
}


// handle the events associated to each button
public void handleButtonEvents(GButton button, GEvent event) {
    if (btnStart == button) {
        println("new surface.");
        surfaceWindow();
        return;
    }

    if (btnFlow == button) {
        flowing = !flowing;
        println("Change Flowing to : " + flowing);
        if(!flowing)
          btnFlow.setText("Start flow");
        else
          btnFlow.setText("Stop flow");
        return;
    }


    for(int i=0;i<nbS;i++) {
      if (surfaces[i].menuB == button) {
          editing = i;
          buttonsVisibility(false);
      }
    }

    if (editFlow == button) {
        String r = flowT.getText();
        if(r.isEmpty())
            return;
        for (int i=0; i< r.length();i++) {
            if (r.charAt(i) <'0' || r.charAt(i) > '9') {
                println("not an int");
                flowT.setText("");
                return;
            }
        }
        int f = Integer.parseInt(r);
        if (f < 0 || f > 8) {
                println("must be between 0 and 8");
                flowT.setText("");
                return;
        }
        if(surfaces[editing].flow < 0)
            f = -f;
        surfaces[editing].flow = f;
        flowT.setText("");
        refreshFlowButtons();
        return;
    }

    if (editActiveFlow == button) {
        surfaces[editing].flow *= -1;
        refreshFlowButtons();
        return;
    }

    if (editTau == button) {
       String r = tauT.getText();
       if(r.isEmpty())
           return;
       try {
           float t = Float.parseFloat(r);
           if (t <= 0 || t > 1) {
               println("bad value (need in ]0,1])");
               tauT.setText("");
               return;
           }
           surfaces[editing].tau = t;
           tauT.setText("");
           editTau.setText("Tau factor = " + surfaces[editing].tau);
           return;
       } catch(Exception e) {
           println("not an float");
           tauT.setText("");
           return;
       }
   }

    if (editSurface == button) {
        String filename = G4P.selectInput("Input Dialog", "txt", "Surface file");
        try{
            if(filename.isEmpty())
                return;
            Surface temp = new Surface(filename);
            surfaces[editing].S = temp;
            surfaces[editing].initialVol =  surfaces[editing].S.volume();
        } catch(Exception e) {
            println("can't use this file");
            return;
        }
        return;
    }
    if (endEdit == button) {
        editing = -1;
        buttonsVisibility(true);
        flowT.setText("");
        tauT.setText("");
        return;
    }
}

// update mouse position if the button is active
public void windowMouse(PApplet appc, GWinData data, MouseEvent event) {
    MyWinData d = (MyWinData)data;
    switch(event.getAction()) {
    case MouseEvent.PRESS:
      d.rotaX = appc.mouseX;
      d.rotaY = appc.mouseY;
      break;
    case MouseEvent.DRAG:
      d.rotaX = appc.mouseX;
      d.rotaY = appc.mouseY;
      break;
    }
}

// zoom in and out funcionality
public void windowKey(PApplet appc, GWinData data, KeyEvent ev) {
    MyWinData d = (MyWinData)data;
    if(ev.getAction() == KeyEvent.PRESS) {
        switch(ev.getKey()) {
          case 'z':
            for(int i=0; i<d.S.positions.size(); i++) {
              d.S.positions.get(i).mult(0.9);
            }
            d.initialVol = d.S.volume();
            break;
          case 'a':
            for(int i=0; i<d.S.positions.size(); i++) {
              d.S.positions.get(i).mult(1.1);
            }
            d.initialVol = d.S.volume();
            break;
        }
    }
}

// draw a window
public void windowDraw(PApplet appc, GWinData data) { // width partout
    MyWinData d = (MyWinData)data;
    appc.background(50);
    appc.camera(appc.width, appc.width, 1800, appc.width/2, appc.width/2, appc.width/2, 0, 1, 0);
    appc.translate(appc.width/2, appc.width/2, 0);

    appc.rotateX(TWO_PI * d.rotaX / appc.width);
    appc.rotateY(TWO_PI * d.rotaY / appc.width);

    appc.line(0,0,0,appc.width*10,0,0);
    appc.line(0,0,0,0,appc.width*10,0);
    appc.line(0,0,0,0,0,appc.width*10);

    if(flowing && d.flow > 0) {
        applyFlow(d);
    }

    d.S.drawSurface(appc);
}

// create a window
public void surfaceWindow() {
  if(nbS >= maxS) {
      println("max surfaces, no more creation");
      return;
  }
  GWindow mywindow = GWindow.getWindow(this, "Surface", 50, 50, 600, 600, P3D);  //P3D
  MyWinData mydata = new MyWinData();

  mydata.S = new Surface("cube.txt");
  mydata.initialVol =  mydata.S.volume();

  mydata.flow = 0;
  mydata.menuB = new GButton(this, 130 + nbS*110, 70, 80, 80, "Surface n°" + nbS);


  mywindow.addData(mydata);
  mywindow.addDrawHandler(this, "windowDraw");
  mywindow.addMouseHandler(this, "windowMouse");
  mywindow.addKeyHandler(this,"windowKey");
  mywindow.setActionOnClose(GWindow.KEEP_OPEN);

  surfaces[nbS] = mydata;
  nbS++;
}