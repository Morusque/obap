
import javax.swing.filechooser.FileSystemView;

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

float audioActionTimer = 5;

void setup() {
  size(700, 220);
  String[] files = getDrives();
  for (String f : files) foldersToExplore.add(new Directory(f, 1));
  ac = AudioContext.getDefaultContext();
  Gain g = new Gain(2, 0.5);
  ac.out.addInput(g);
  for (int i=0; i<nbPlayers; i++) {
    panners[i] = new Panner(ac, 0);
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
  text("exploring "+foldersToExplore.size()+" folders", 20, 30);
  text("found "+filesToPlay.size()+" audio files", 20, 50);
  text("sounds currently playing : ", 20, 70);
  int currentY = 90;
  for (int i=0; i<nbPlayers; i++) {
    if (players[i]!=null) {
      if (!players[i].isPaused()&&!players[i].isDeleted()) {
        text("   "+playerUrls[i], 20, currentY);
        currentY+=20;
      }
    }
  }
  if (filesToPlay.size()>0) {
    int nbFilesPlaying = 0;
    for (SamplePlayer p : players) if (p!=null) if (!p.isPaused()&&!p.isDeleted()) nbFilesPlaying++;        
    if (audioActionTimer > 5 || nbFilesPlaying==0) {
      try {
        if (players[currentPlayer]!=null) if (!players[currentPlayer].isPaused()&&!players[currentPlayer].isDeleted()) players[currentPlayer].kill();
        playerUrls[currentPlayer] = filesToPlay.remove(0);
        players[currentPlayer] = new SamplePlayer(SampleManager.sample(playerUrls[currentPlayer]));
        players[currentPlayer].setKillOnEnd(true);
        players[currentPlayer].setPosition(random((float)players[0].getSample().getLength()));
        float rate = 1;
        if (random(1)<0.2) rate = random(1, random(0, 2));
        if (random(1)<0.2) rate *= -1;
        players[currentPlayer].setRate(new Static(rate));
        panners[currentPlayer].clearInputConnections();
        panners[currentPlayer].addInput(players[currentPlayer]);
        panners[currentPlayer].setPos(random(-1, 1));
        audioActionTimer = 0;
        currentPlayer = (currentPlayer+1)%nbPlayers;
      }
      catch(Exception e) {
        println(e);
      }
    }
  } else {
    while (filesToPlay.size()==0&&foldersToExplore.size()>0) exploreDeeper();
    if (foldersToExplore.size()==0) exit();
  }
  exploreDeeper();
  audioActionTimer += 1.0f/frameRate;
}

void exploreDeeper() {
  if (foldersToExplore.size()>0) {
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
      int nbFilesAdded = 0;
      for (String f : discoveries[1]) {
        String extension = extension(f); 
        if (extension.equals("wav")||extension.equals("mp3")||extension.equals("aif")||extension.equals("aiff")||extension.equals("ogg")||extension.equals("flac")) {
          filesToPlay.add(f);
          nbFilesAdded++;
        }
      }
      if (nbFilesAdded>0) randomizeArrayList(filesToPlay);
    }
    catch(Exception e) {
      // println(e);
    }
  }
}

<T> void randomizeArray(T[] as) {
  ArrayList<T> a1 = new ArrayList<T>();
  ArrayList<T> a2 = new ArrayList<T>();
  for (T a : as) a1.add(a);

  while (a1.size()>0) a2.add(a1.remove(floor(random(a1.size()))));
  for (int i=0; i<as.length; i++) as[i]=a2.get(i);
}

<T> void randomizeArrayList(ArrayList<T> as) {
  ArrayList<T> a2 = new ArrayList<T>();
  while (as.size()>0) a2.add(as.remove(floor(random(as.size()))));
  for (T a : a2) as.add(a);
}

String extension (String e) {
  int pos = e.length()-1;
  while (pos>0) {
    if (e.charAt(pos)=='.') return e.substring(pos+1, e.length()).toLowerCase();
    pos--;
  }
  return "";
}

class Directory {
  String path;
  float weight;
  Directory(String path, float weight) {  
    this.path = path;
    this.weight = weight;
  }
}
