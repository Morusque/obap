
import javax.swing.filechooser.FileSystemView;

ArrayList<String> foldersToExplore = new ArrayList<String>();
ArrayList<String> filesToPlay = new ArrayList<String>();

import ddf.minim.*;

Minim minim;
AudioPlayer[] player = new AudioPlayer[5];
String[] playerUrls = new String[5];
int currentPlayer = 0;

float audioActionTimer = 5;

void setup() {
  size(500, 200);
  minim = new Minim(this);  
  String[] files = getDrives();
  for (String f : files) foldersToExplore.add(f);
}

void draw() {
  // println(foldersToExplore);
  // println(filesToPlay);
  // println("---");
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
    randomizeArrayList(filesToPlay);
    int nbFilesPlaying = 0;
    for (AudioPlayer p : player) if (p!=null) if (p.isPlaying()) nbFilesPlaying++;        
    if (audioActionTimer > 5 || nbFilesPlaying==0) {
      try {
        if (player[currentPlayer]!=null) {
          player[currentPlayer].pause();
          player[currentPlayer].rewind();
        }
        playerUrls[currentPlayer] = filesToPlay.remove(0);
        player[currentPlayer] = minim.loadFile(playerUrls[currentPlayer]);
        if (player[currentPlayer].length()!=-1) player[currentPlayer].skip(floor(random(player[currentPlayer].length())));
        player[currentPlayer].play();
        audioActionTimer = 0;
        currentPlayer = (currentPlayer+1)%player.length;
      }
      catch(Exception e) {
        println(e);
      }
    }
  } else {
    while (filesToPlay.size()==0) exploreDeeper();
  }
  exploreDeeper();
  audioActionTimer += 1.0f/frameRate;
}

void exploreDeeper() {
  if (foldersToExplore.size()>0) {
    randomizeArrayList(foldersToExplore);
    String folder = foldersToExplore.remove(0);
    try {
      String[][] discoveries = getAllFoldersAndFilesFrom(folder);
      for (String f : discoveries[0]) foldersToExplore.add(f);
      for (String f : discoveries[1]) {
        String extension = extension(f); 
        if (extension.equals(".wav")||extension.equals(".mp3")) {
          filesToPlay.add(f);
        }
      }
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
