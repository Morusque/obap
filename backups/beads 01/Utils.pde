
import java.io.*;
import java.awt.*;

public float vrMax(float a, float b, float m) {
  float d1=b-a;
  if (d1>m/2) {
    d1=d1-m;
  }
  if (d1<-m/2) {
    d1=d1+m;
  }
  return d1;
}

String getDialogFileUrl(String label) {
  Frame frame = new Frame();
  FileDialog fileDialog = new FileDialog(frame, label, FileDialog.LOAD);
  fileDialog.setVisible(true);
  if (fileDialog.getFile()!=null) {
    String filePath = fileDialog.getDirectory() + fileDialog.getFile();
    return filePath;
  }
  return null;
}

String getDialogFolderUrl(String label) {
  Frame frame = new Frame();
  FileDialog fileDialog = new FileDialog(frame, label, FileDialog.LOAD);
  fileDialog.setVisible(true);
  return fileDialog.getDirectory();
}

String[] getDialogAllFilesUrl(String label) {
  Frame frame = new Frame();
  FileDialog fileDialog = new FileDialog(frame, label, FileDialog.LOAD);
  fileDialog.setVisible(true);
  return getAllFilesFrom(fileDialog.getDirectory());
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

String[][] getAllFoldersAndFilesFrom(String folderUrl) {
  File folder = new File(folderUrl);
  File[] filesPath = folder.listFiles();
  ArrayList<String> folders = new ArrayList<String>();
  ArrayList<String> files = new ArrayList<String>();
  for (int i=0; i<filesPath.length; i++) {
    if (filesPath[i].isDirectory()) folders.add(filesPath[i].toString());
    else files.add(filesPath[i].toString());
  }
  String[][] result = new String[2][];
  result[0] = folders.toArray(new String[folders.size()]);
  result[1] = files.toArray(new String[files.size()]);
  return result;
}

String[][] getAllFoldersAndFilesMaxSizeFrom(String folderUrl, float limitMb) {
  File folder = new File(folderUrl);
  File[] filesPath = folder.listFiles();
  ArrayList<String> folders = new ArrayList<String>();
  ArrayList<String> files = new ArrayList<String>();
  for (int i=0; i<filesPath.length; i++) {
    if (filesPath[i].isDirectory()) folders.add(filesPath[i].toString());
    else {
      if (filesPath[i].length() / (1024 * 1024) <= limitMb) files.add(filesPath[i].toString());
    }
  }
  String[][] result = new String[2][];
  result[0] = folders.toArray(new String[folders.size()]);
  result[1] = files.toArray(new String[files.size()]);
  return result;
}

String[] getDrives() {
  File[] paths;
  // FileSystemView fsv = FileSystemView.getFileSystemView();
  paths = File.listRoots();
  String[] urls = new String[paths.length];
  for (int i=0;i<paths.length;i++) urls[i] = paths[i].toString();
  //fsv.getSystemTypeDescription(paths[i])
  return urls;
}

public void renameFile(String urlA, String urlB) {
  File file = new File(sketchPath(urlA));
  File file2 = new File(sketchPath(urlB));  
  boolean success = file.renameTo(file2);
  if (!success) {
    println(urlA + " was not renamed to " + urlB);
  }
}

public void copyDirectory(String urlA, String urlB) throws IOException {
  File srcDir = new File(sketchPath(urlA));
  File dstDir = new File(sketchPath(urlB));  
  try {
    copyDirectoryRec(srcDir, dstDir);
  } 
  catch (IOException e) {
    e.printStackTrace();
  }
}

public void copyDirectoryRec(File srcDir, File dstDir) throws IOException {
  // Copies all files under srcDir to dstDir.
  // If dstDir does not exist, it will be created.
  if (srcDir.isDirectory()) {
    if (!dstDir.exists()) {
      dstDir.mkdir();
    }
    String[] children = srcDir.list();
    for (int i=0; i<children.length; i++) {
      copyDirectoryRec(new File(srcDir, children[i]), new File(dstDir, children[i]));
    }
  } else {
    // This method is implemented in Copying a File
    copyFile(srcDir, dstDir);
  }
}

void copyFile(File src, File dst) throws IOException {
  // Copies src file to dst file.
  // If the dst file does not exist, it is created
  InputStream in = new FileInputStream(src);
  OutputStream out = new FileOutputStream(dst);

  // Transfer bytes from in to out
  byte[] buf = new byte[1024];
  int len;
  while ( (len = in.read (buf)) > 0) {
    out.write(buf, 0, len);
  }
  in.close();
  out.close();
}


PImage extractFromBackground(PImage entireCap, PImage background, float distoMask) {
  PImage mask = createImage(background.width, background.height, RGB);
  PImage maskedCap = entireCap.get();
  for (int x=0; x<background.width; x++) {
    for (int y=0; y<background.height; y++) {
      color a = maskedCap.get(x, y);
      color b = background.get(x, y);
      mask.set(x, y, color(constrain(abs(red(a)-red(b))*distoMask, 0, 0xFF), constrain(abs(green(a)-green(b))*distoMask, 0, 0xFF), constrain(abs(blue(a)-blue(b))*distoMask, 0, 0xFF)));
    }
  }
  maskedCap.mask(mask);
  PGraphics maskedGraphics = createGraphics(maskedCap.width, maskedCap.height, JAVA2D);
  maskedGraphics.beginDraw();
  maskedGraphics.image(maskedCap, 0, 0);
  maskedGraphics.endDraw();
  maskedCap = maskedGraphics.get();
  return maskedCap;
}

String findAndReplace(String o, String f, String r) {
  for (int i=0; i<=o.length ()-f.length(); i++) {
    if (o.substring(i, i+f.length()).equals(f)) {
      o = o.substring(0, i)+r+o.substring(i+f.length(), o.length());
      i+=r.length()-1;
    }
  }
  return o;
}

int strPos(String haystack, String needle) {
  for (int i=0; i<=haystack.length()-needle.length(); i++) if (haystack.substring(i, i+needle.length()).equals(needle)) return i;
  return -1;
}

String[] loadStringsEnc(String url) {
  InputStream input = createInput(url);
  BufferedReader reader = null;
  try {
    reader = new BufferedReader(new InputStreamReader(input, "ISO-8859-1")); // loadStrings() does that with "UTF-8"
  } 
  catch (IOException e) {
    e.printStackTrace();
    exit();
  }
  String[] web = loadStrings(reader);
  return web;
}

boolean contains(PVector[] points, PVector test) {
  int i;
  int j;
  boolean result = false;
  for (i = 0, j = points.length - 1; i < points.length; j = i++) {
    if ((points[i].y > test.y) != (points[j].y > test.y) &&
      (test.x < (points[j].x - points[i].x) * (test.y - points[i].y) / (points[j].y-points[i].y) + points[i].x)) {
      result = !result;
    }
  }
  return result;
}

boolean inArray(String[] hs, String n) {
  for (String s : hs) {
    if (s.equals(n)) return true;
  }
  return false;
}

color average(final PImage img) {
  img.loadPixels();
  long r = 0, g = 0, b = 0;
  for (final color c : img.pixels) {
    r += c >> 020 & 0xFF;
    g += c >> 010 & 0xFF;
    b += c        & 0xFF;
  }
  r /= img.pixels.length;
  g /= img.pixels.length;
  b /= img.pixels.length;
  return color((int)r, (int)g, (int)b);
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
