
ArrayList<Directory> foldersToExplore = new ArrayList<Directory>();
ArrayList<String> filesToPlay = new ArrayList<String>();

import java.util.Arrays;
import processing.sound.*;

ArrayList<Player> players = new ArrayList<Player>();

long nextPlayTime = 0;

int activeThread = 0;
// 0 = -> explore
// 1 = exploring
// 2 = -> play
// 3 = playing

PApplet applet;

void setup() {
  size(700, 220);
  frameRate(30);
  applet = this;
  String[] files = getDrives();
  for (String f : files) foldersToExplore.add(new Directory(f, 1));
}

void draw() {
  background(0);
  stroke(0x50);
  /*
  for (int i = 0; i < width; i++) {
    int buffIndex = i * ac.getBufferSize() / width;
    int vOffset = (int)((1 + ac.out.getValue(0, buffIndex)) * height / 2);
    vOffset = min(vOffset, height);
    point(i, vOffset);
  } 
  */
  fill(0xFF);
  textSize(10);
  text(""+foldersToExplore.size()+" folders to explore", 20, 30);
  text(""+filesToPlay.size()+" files to play", 20, 50);
  text("play log : ", 20, 70);
  int currentY = 90;
  for (int i=0; i<players.size(); i++) {
    if (players.get(i).isPlaying()) {
      text("   "+players.get(i).url, 20, currentY);
      currentY+=20;
    }
  }
  if (activeThread==0) {
    activeThread=1;
    thread("exploreDeeper");
  }
  if (activeThread==2) {
    activeThread=3;
    thread("playSomething");
  }

  //println("---");
  //ac.printCallChain();
  //SampleManager.printSampleList();
}

void exploreDeeper() {
  if (foldersToExplore.size()>0 && filesToPlay.size()<1000) {
    float totalWeights = 0;
    for (Directory f : foldersToExplore) totalWeights += f.weight;
    float target = random(totalWeights);
    totalWeights = 0;
    int targetI=0;
    for (int i=0; i<foldersToExplore.size(); i++) {
      totalWeights += foldersToExplore.get(i).weight;
      if (totalWeights>=target) {
        targetI = i;
        break;
      }
    }
    Directory thisDirectory = foldersToExplore.remove(targetI);
    float thisWeight = thisDirectory.weight;
    String thisPath = thisDirectory.path;
    try {
      String[][] discoveries = getAllFoldersAndFilesMaxSizeFrom(thisPath, 20);
      float childrenWeight = thisWeight/max(1, discoveries[0].length);
      for (String f : discoveries[0]) {
        Directory newDir = new Directory(f, childrenWeight);
        foldersToExplore.add(newDir);
      }
      for (String f : discoveries[1]) {
        String extension = extension(f); 
        if (extension.equals("wav")||extension.equals("mp3")||extension.equals("aif")||extension.equals("aiff")||extension.equals("flac")) {//||extension.equals("ogg") 
          filesToPlay.add(f);
        }
      }
    }
    catch(Exception e) {
      // println(e);
    }
  }
  if (foldersToExplore.size()+filesToPlay.size()==0) exit();
  activeThread = 2;
}

void playSomething() {
  if (filesToPlay.size()>0) {
    if (millis()>=nextPlayTime) {
      try {
        players.add(new Player());
        if (players.size()>5) {
          players.get(0).delete();
          System.gc();
        }
        nextPlayTime = floor(millis()+random(100, 10000));
      }
      catch(Exception e) {
        println(e);
      }
    }
  }
  activeThread = 0;
}

class Directory {
  String path;
  float weight;
  Directory(String path, float weight) {  
    this.path = path;
    this.weight = weight;
  }
}

class Player {
  SoundFile file;
  String url;
  Player() {
    url = filesToPlay.remove(floor(random(filesToPlay.size())));
    file = new SoundFile(applet, url);
    file.pan(random(-1,1));
    float rate = 1;
    if (random(1)<0.3) rate = random(1, random(0, 2));
    if (random(1)<0.2) rate *= -1;
    file.rate(rate);
    file.cue(random((float)file.duration()));
    file.play();
  }
  void delete() {
    file.stop();
    file = null;
    players.remove(this);
  }
  boolean isPlaying() {
    if (file == null) return false;
    if (url == null) return false;
    if (file.isPlaying()) return true;
    return false;
  }
}
