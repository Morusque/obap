
ArrayList<Directory> foldersToExplore = new ArrayList<Directory>();
ArrayList<String> filesToPlay = new ArrayList<String>();

import beads.*;
import java.util.Arrays; 

AudioContext ac;
ArrayList<Player> players = new ArrayList<Player>();

long nextPlayTime = 0;

int activeThread = 0;
// 0 = -> explore
// 1 = exploring
// 2 = -> play
// 3 = playing

void setup() {
  size(700, 220);
  frameRate(30);
  String[] files = getDrives();
  for (String f : files) foldersToExplore.add(new Directory(f, 1));
  ac = AudioContext.getDefaultContext();
  ac.start();
}

void draw() {
  background(0);
  stroke(0x50);
  for (int i = 0; i < width; i++) {
    int buffIndex = i * ac.getBufferSize() / width;
    int vOffset = (int)((1 + ac.out.getValue(0, buffIndex)) * height / 2);
    vOffset = min(vOffset, height);
    point(i, vOffset);
  }  
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
        if (extension.equals("wav")||extension.equals("aif")||extension.equals("aiff")||extension.equals("flac")||extension.equals("mp3")) {//||extension.equals("ogg")
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
  SamplePlayer player;
  Panner panner;
  Gain gain;
  String url;
  Player() {
    url = filesToPlay.remove(floor(random(filesToPlay.size())));
    player = new SamplePlayer(SampleManager.sample(url));
    panner = new Panner(ac, 0);
    gain = new Gain(2, 0.5);
    panner.setPos(random(-1, 1));
    panner.addInput(player);
    player.setKillOnEnd(true);
    float rate = 1;
    if (random(1.0f)<0.3f) rate = random(1.0f, random(0.0f, 2.0f));
    if (random(1.0f)<0.2f) rate *= -1;
    player.setRate(new Static(rate));
    panner.addInput(player);
    gain.addInput(panner);
    ac.out.addInput(gain);
    player.start(random((float)player.getSample().getLength()));
  }
  void delete() {
    player.pause(true);
    if (player.getSample()!=null) {
      SampleManager.removeSample(player.getSample());
      player.getSample().clear();
    }
    player.removeAllConnections(panner);
    panner.removeAllConnections(gain);
    gain.removeAllConnections(ac.out);
    panner.kill();
    player.kill();
    gain.kill();
    players.remove(this);
  }
  boolean isPlaying() {
    if (player.isDeleted()) return false;
    if (url == null) return false;
    return true;
  }
}
