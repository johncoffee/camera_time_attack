import processing.video.*;

Capture video;

int t0 = 0, t1 = 0;
boolean cameraOn = true;
float threshold = 60;
int numPixels;
int[] previousFrame;

int state = 0;
final static int
  IDLE = 0, 
  RUNNING = 1; // IDLE, RUNNING

boolean[][]startArea, finishArea; 

void setup() {
  noSmooth();
  noStroke();
  frameRate(30);

  size(320, 180); //6 name=FaceTime HD Camera (Built-in),size=320x180,fps=30

  background(#000000);
  stroke(#ffffff);
  text("Waiting for camera...", width*0.333, height/2.0);

  video = getCamera();
  if (video == null) exit();

  numPixels = video.width * video.height;

  // game state:
  previousFrame = new int[numPixels];

  startArea = new boolean[width][height];
  finishArea = new boolean[width][height];
}

void draw() {
  if (video.available()) {
    drawGame(video);
  }
}

Capture getCamera() {
  Capture video = null;

  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i + " " + cameras[i]);
    }

    // The camera can be initialized directly using an 
    // element from the array returned by list():
    video = new Capture(this, width, height, cameras[6]);
    video.start();
  }  
  return video;
}

void drawGame(Capture video) {

  video.read();
  video.loadPixels();
  ArrayList<PVector> list = runDiff(video);

  if (cameraOn) {
    set(0, 0, video);
  } else {
    background(#000000);
  }

  // add to blobs
  if (mousePressed &&
    mouseX < width && mouseX >= 0 && 
    mouseY >=0 && mouseY < height) {

    if ( (mouseButton == LEFT)) {
      startArea[mouseX][mouseY] = 
        startArea[mouseX][mouseY+1] =
        startArea[mouseX+1][mouseY] =
        startArea[mouseX+1][mouseY+1] =
        true;
    } else if ( (mouseButton == RIGHT)) {          
      finishArea[mouseX][mouseY] = 
        finishArea[mouseX][mouseY+1] =
        finishArea[mouseX+1][mouseY] =
        finishArea[mouseX+1][mouseY+1] =
        true;
    }
  }

  // check collisions
  switch (state) {
  case IDLE:
    boolean shouldStart = checkCollision(list, startArea);
    if (shouldStart) {
      state = RUNNING;
      t0 = millis();
    }
    break;
  case RUNNING:
    boolean isCollided = checkCollision(list, finishArea);
    if (isCollided) {
      state = IDLE;
      t1 = millis();
    }
    break;
  }  

  //print(list.size() + " "); // how many pixels are different?

  renderBooleans(list, #aaaaaa);  
  renderBooleans(finishArea, #ffff00);
  renderBooleans(startArea, #80aaff);

  float dTime = t1 - t0;
  if (dTime > 0) {
    fill(#ffffff);
    textSize(100); 
    text((round(dTime/1000.0))+"", width*0.333, height/2.0);
  }
}


ArrayList<PVector> runDiff(Capture video) {
  ArrayList<PVector> list = new ArrayList<PVector>();
  for (int x = 0; x < video.width; x++) {
    for (int y = 0; y < video.height; y++) {
      int i = x + (y * video.width);
      color currColor = video.pixels[i];
      color prevColor = previousFrame[i];

      int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;

      int prevR = (prevColor >> 16) & 0xFF;
      int prevG = (prevColor >> 8) & 0xFF;
      int prevB = prevColor & 0xFF;

      int diffR = abs(currR - prevR);
      int diffG = abs(currG - prevG);
      int diffB = abs(currB - prevB);

      if (diffR + diffG + diffB > threshold) {  
        list.add(new PVector(x, y));
      }

      previousFrame[i] = currColor;
    }
  }

  return list;
}

boolean checkCollision(ArrayList<PVector> list, boolean[][] map) {  
  for (int i = 0, c = list.size(); i < c; i++) {
    PVector p = list.get(i);       
    if (
      p.y < height && p.y > 0 && 
      p.x > 0 && p.x < width &&
      map[floor(p.x)][floor(p.y)]) {
      return true;
    }
  }
  return false;
}

void renderBooleans(ArrayList<PVector> list, color colour) {
  //fill(colour);
  stroke(colour);
  for (int i = 0, c = list.size(); i < c; i += 2) { // draw every second pixel. Hax performance fix.
    PVector p = list.get(i);
    //rect(p.x, p.y, 10, 10);
    point(p.x, p.y);    
  }
}

void renderBooleans(boolean[][] map, color colour) {
  //fill(colour);
  stroke(colour);
  for (int x = 0; x < map.length; x++) { 
    for (int y = 0; y < map[x].length; y++) {
      if (x < width && y < height && map[x][y]) {              
        //rect(x, y, 10, 10);
        point(x, y);        
      }
    }
  }
}


void keyPressed() {
  //println(keyCode);
  switch (keyCode) {
  case 38: //up
    threshold += 20;
    break;
  case 40: //up
    threshold -= 20;
    break;
  case 32:
    cameraOn = !cameraOn;
    break;
    //case 
  case 82: // r
    startArea = new boolean[width][height];
    finishArea = new boolean[width][height];
    break;
  }
}