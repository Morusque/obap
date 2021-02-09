
import javax.swing.filechooser.FileSystemView;

ArrayList<Directory> foldersToExplore = new ArrayList<Directory>();
ArrayList<String> filesToPlay = new ArrayList<String>();

//import ddf.minim.*;
import processing.sound.*;

//Minim minim;
SoundFile[] player = new SoundFile[5];
String[] playerUrls = new String[5];
int currentPlayer = 0;

float audioActionTimer = 5;

void setup() {
  size(700, 220);
  String[] files = getDrives();
  for (String f : files) foldersToExplore.add(new Directory(f, 1));
}

void draw() {
  background(0);
  fill(0xFF);
  textSize(10);
  text("exploring "+foldersToExplore.size()+" folders", 20, 30);
  text("found "+filesToPlay.size()+" audio files", 20, 50);
  text("sounds currently playing : ", 20, 70);
  int currentY = 90;
  for (int i=0; i<player.length; i++) {
    if (player[i]!=null) {
      if (player[i].isPlaying()) {
        text("   "+playerUrls[i], 20, currentY);
        currentY+=20;
      }
    }
  }
  if (filesToPlay.size()>0) {
    int nbFilesPlaying = 0;
    for (SoundFile p : player) if (p!=null) if (p.isPlaying()) nbFilesPlaying++;        
    if (audioActionTimer > 5 || nbFilesPlaying==0) {
      try {
        if (player[currentPlayer]!=null) if (player[currentPlayer].isPlaying()) player[currentPlayer].pause();
        playerUrls[currentPlayer] = filesToPlay.remove(0);
        SoundFile newSF = new SoundFile(this, playerUrls[currentPlayer]);// false should be added to enable garbage collection
        player[currentPlayer] = newSF;
        if (player[currentPlayer].duration()!=-1) player[currentPlayer].cue(floor(random(player[currentPlayer].duration())));
        if (player[currentPlayer].channels()==1) player[currentPlayer].pan(random(-1, 1));
        if (random(1)<0.7) player[currentPlayer].rate(1);
        else player[currentPlayer].rate(random(random(random(0, 2), 1), 1));
        player[currentPlayer].play();
        audioActionTimer = 0;
        currentPlayer = (currentPlayer+1)%player.length;
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
        if (extension.equals(".wav")||extension.equals(".mp3")||extension.equals("aif")||extension.equals("aiff")) {
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

String extension (String e) {// TODO better
  if (e.length()<4) return "";
  return e.substring(e.length()-4, e.length()).toLowerCase();
}

class Directory {
  String path;
  float weight;
  Directory(String path, float weight) {  
    this.path = path;
    this.weight = weight;
  }
}
