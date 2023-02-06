
import beads.*;
import java.util.Arrays; 

ArrayList<String> filesToPlay = new ArrayList<String>();
ArrayList<Player> players = new ArrayList<Player>();

AudioContext ac;
Gain gain = new Gain(2, 0.5);

void setup() {
  size(300, 300);
  frameRate(30);
  ac = AudioContext.getDefaultContext();
  ac.out.addInput(gain);
  ac.start();
  String[] files = getAllFilesFrom("D:/project/ongoing/radio quantité/musique");
  for (String f : files) filesToPlay.add(f);
}

void draw() {
}

void keyPressed() {
  playSomething();
}

void playSomething() {
  if (filesToPlay.size()>0) players.add(new Player());
  if (players.size()>2) players.get(0).kill();
}

class Player {
  SamplePlayer samplePlayer;
  Panner panner;
  String url;

  Player() {
    try {
      url = filesToPlay.remove(floor(random(filesToPlay.size())));
      samplePlayer = new SamplePlayer(SampleManager.sample(url));
      panner = new Panner(ac, 0);
      panner.setPos(0);
      panner.addInput(samplePlayer);
      samplePlayer.setKillOnEnd(true);
      panner.addInput(samplePlayer);
      gain.addInput(panner);
      samplePlayer.start();
    }
    catch(Exception e) {
      println(e);
    }
  }

  void kill() {
    try {
      samplePlayer.pause(true);
      if (samplePlayer.getSample()!=null) {
        SampleManager.removeSample(samplePlayer.getSample());
        samplePlayer.getSample().clear();
      }
      gain.removeAllConnections(panner);
      panner.removeAllConnections(samplePlayer);
      panner.kill();
      samplePlayer.kill();
    }
    catch(Exception e) {
      println(e);
    }
    players.remove(this);
  }
}

String[] getAllFilesFrom(String folderUrl) {
  File folder = new File(folderUrl);
  File[] filesPath = folder.listFiles();
  String[] result = new String[filesPath.length];
  for (int i=0; i<filesPath.length; i++) {
    result[i]=filesPath[i].toString();
  }
  return result;
}
