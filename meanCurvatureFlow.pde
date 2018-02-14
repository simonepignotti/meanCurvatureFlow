import g4p_controls.*;

int nVmax = 2000;
int nEmax = 2000;
int nFmax = 3500;

int maxS = 6;


/**/
float maxFlowComp = 100;
Float pInfiniteFloat = Float.POSITIVE_INFINITY;
Float nInfiniteFloat = Float.NEGATIVE_INFINITY;
/**/


GButton btnStart;
GButton btnFlow;

GButton editFlow;
GButton editActiveFlow;
GButton editTau;
GButton editSurface;
GButton endEdit;

GTextField flowT;
GTextField tauT;

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
  
  
  //EDITING
  
  editFlow = new GButton(this, 40, 30, 120, 90, "Flow type");
  editTau = new GButton(this, 250, 30, 120, 90, "Tau factor");
  
  editActiveFlow = new GButton(this, 40, 180,120, 90, "Active");
  editSurface = new GButton(this, 250, 180, 120, 90, "Surface File");
  endEdit = new GButton(this, 460, 180, 120, 90, "OK");
  
  flowT = new GTextField(this, 50, 140, 110, 24);
  tauT  = new GTextField(this, 260, 140, 110, 24);
  
  flowT.setPromptText("new flow value"); 
  tauT.setPromptText("new tau value");
  
  //EDITING
  
  buttonsVisibility(true);
}

void draw() {
  if(editing == 0)
    background(230, 230, 230);
  background(130, 130, 130);
}

void buttonsVisibility(boolean menu) {
    btnStart.setVisible(menu);
    btnFlow.setVisible(menu);
    for(int i=0;i<nbS;i++) {
        surfaces[i].menuB.setVisible(menu);
    }
    
    editFlow.setVisible(!menu);
    editActiveFlow.setVisible(!menu);
    editTau.setVisible(!menu);
    editSurface.setVisible(!menu);
    endEdit.setVisible(!menu);
    
    flowT.setVisible(!menu);
    tauT.setVisible(!menu);
    
    refreshFlowButtons();
    
}

void refreshFlowButtons() {
    if(editing >= 0) {
        if(surfaces[editing].flow > 0)
            editActiveFlow.setText("Active");
        else
            editActiveFlow.setText("Inactive");
        editFlow.setText("Flow type = " + surfaces[editing].flow);
        editTau.setText("Tau factor = " + surfaces[editing].tau);
    }
}

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
        if (f < 0 || f > 3) {
                println("must be between 0 and 3");
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
        for (int i=0; i< r.length();i++) {
            if (r.charAt(i) <'0' || r.charAt(i) > '9') {
                println("not an int");
                tauT.setText("");
                return;
            } 
        }
        float t = Float.parseFloat(r);
        if (t < 0 || t > 1000) {
                println("must be between 0 and 1000");
                tauT.setText("");
                return;
        }
        t = t/1000;
        
        surfaces[editing].tau = t;
        tauT.setText("");
        editTau.setText("Tau factor = " + surfaces[editing].tau);
        return;
    }
    
    if (editSurface == button) {
        String filename = G4P.selectInput("Input Dialog", "txt", "Surface file");
        try{
            if(filename.isEmpty())
                return;
            Surface temp = new Surface(filename);
            surfaces[editing].S = temp;
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
        println("Flowing active");
        applyFlow(d);
    }/**/
      
    d.S.drawSurface(appc);
}

public void surfaceWindow() {
  if(nbS >= maxS) {
      println("max surfaces, no more creation");
      return;
  }
  GWindow mywindow = GWindow.getWindow(this, "Surface", 50, 50, 600, 600, P3D);  //P3D
  MyWinData mydata = new MyWinData();
 
  mydata.S = new Surface("cube.txt");
  mydata.initialVol =  mydata.S .volume();
  
  mydata.flow = 0;
  mydata.menuB = new GButton(this, 130 + nbS*110, 70, 80, 80, "Surface n°" + nbS);
  
   //<>//
  mywindow.addData(mydata); 
  mywindow.addDrawHandler(this, "windowDraw");
  mywindow.addMouseHandler(this, "windowMouse");
  mywindow.addKeyHandler(this,"windowKey");
  mywindow.setActionOnClose(GWindow.KEEP_OPEN);
  
  surfaces[nbS] = mydata;
  nbS++;
}


void keyReleased() {
  
  if (key == 'f') {
    flowing = !flowing;
    println("Flowing = ", flowing);
  }
  
  if (key == 'd') {
    //flowHarmoniqueContrain();
    println("1 Flowing ");
  }
}