
ArrayList<Directory> foldersToExplore = new ArrayList<Directory>();
ArrayList<String> filesToPlay = new ArrayList<String>();

import beads.*;
import java.util.Arrays; 

AudioContext ac;
int nbPlayers = 5;
SamplePlayer[] players = new SamplePlayer[nbPlayers];
Panner[] panners = new Panner[nbPlayers];
String[] playerUrls = new String[nbPlayers];

int currentPlayer = 0;

long nextPlayTime = 0;

int activeThread = 0;
// 0 = -> explore
// 1 = exploring
// 2 = -> play
// 3 = playing

ArrayList<String> playedLog = new ArrayList<String>();

void setup() {
  size(700, 220);
  frameRate(30);
  String[] files = getDrives();
  for (String f : files) foldersToExplore.add(new Directory(f, 1));
  ac = AudioContext.getDefaultContext();
  Gain g = new Gain(2, 0.5);
  ac.out.addInput(g);
  for (int i=0; i<nbPlayers; i++) {
    players[i] = new SamplePlayer(ac, 2);
    panners[i] = new Panner(ac, 0);
    // panners[currentPlayer].clearInputConnections();
    panners[i].addInput(players[i]);
    g.addInput(panners[i]);
  }
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
  for (int i=0; i<players.length; i++) {
    if (playerUrls[i]!=null&&!players[i].isDeleted()) {
      text("   "+playerUrls[i], 20, currentY);
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
        players[currentPlayer].pause(true);
        if (players[currentPlayer].getSample()!=null) players[currentPlayer].getSample().clear();
        players[currentPlayer].kill();
        playerUrls[currentPlayer] = filesToPlay.remove(floor(random(filesToPlay.size())));
        players[currentPlayer] = new SamplePlayer(SampleManager.sample(playerUrls[currentPlayer]));
        players[currentPlayer].setKillOnEnd(true);
        float rate = 1;
        if (random(1)<0.3) rate = random(1, random(0, 2));
        if (random(1)<0.2) rate *= -1;
        players[currentPlayer].setRate(new Static(rate));
        panners[currentPlayer].setPos(random(-1, 1));
        panners[currentPlayer].clearInputConnections();
        panners[currentPlayer].addInput(players[currentPlayer]);
        players[currentPlayer].start(random((float)players[currentPlayer].getSample().getLength()));
        nextPlayTime = floor(millis()+random(100, 10000));
        playedLog.add(playerUrls[currentPlayer]);
        while (playedLog.size()>5) playedLog.remove(0);
        currentPlayer = (currentPlayer+1)%nbPlayers;
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
