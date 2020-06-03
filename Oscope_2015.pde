
/*
 * WPI BME2210 Arduino Oscilloscope
 * Gives a visual rendering of analog pin 0 in realtime. 
 * Allows saving of data to a text file.
 * 
 * (c) 2013-2015 Dirk Albrecht (dalbrecht@wpi.edu)
 * 
 * Modified from:
 * (c) 2008 Sofian Audry (info@sofianaudry.com)
 * 
 */ 

import processing.serial.*;
import java.awt.*;
import java.awt.image.*;
import java.awt.datatransfer.*;
import java.io.*;

Serial port;  // Create object from Serial class
int val;      // Data received from the serial port
int[] values, t;
float zoom;
boolean halt, copyClip = false;
String portname, savefile, timestamp = " ";
int bg = 0;
int old_bg = bg;
int numPorts;
int portNum = 0;
boolean portFound = false;

void setup() 
{ 
  size(640, 480);
  
  values = new int[width];  
  t = new int[width];
  
  zoom = 1.0f;
  halt = false;
  
  smooth();
  
  // List all the available serial ports
  //println(Serial.list());

  background(bg);
  fill(255-bg);
  
  numPorts = Serial.list().length;
  portNum = numPorts-1; // Start with last
  port = new Serial(this, Serial.list()[portNum], 19200);
  //text("["+Serial.list()[portNum]+"] "+port.available(),20,56);
  
  //port = new Serial(this, "COM7", 19200);
  

  print("Checking "+numPorts+" USB ports: ");
  
  /*
  while (!portFound && (portNum < numPorts)) {
    // Open serial ports sequantially until one is found:
    try {
     
      portname = Serial.list()[portNum];
      print(portname);
      
      if ((portname.indexOf("COM") >= 0) || (portname.indexOf("usbmodem") >= 0)) {
        port = new Serial(this, Serial.list()[portNum], 19200);
        print("["+Serial.list()[portNum]+"]");
    
        delay(500);
        if (port.available() > 0) {
          portFound = true;
          println("-found ");  
        } else {
          print(" ");
          portNum++;
        }
      } else portNum++;
    } catch (RuntimeException e) { } 
  }
  
  if (!portFound) {
    println(" No USB ports found.");
  }
  */
  //BufferedImage img=null;
}


int getY(int val) {
  return (int)(height - 1 - val / 1023.0f * (height - 1));
}

int getValue() {
  int value = -1;

  while (port.available() >= 3) {
    if (port.read() == 0xff) {
      value = (port.read() << 8) | (port.read());
    }
  }

  return value;
}

void pushValue(int value) {
  for (int i=0; i<width-1; i++) {
    values[i] = values[i+1];
    t[i] = t[i+1];
  }
  values[width-1] = value;
  t[width-1] = millis();
}

void drawLines() {

  stroke(255 - bg);
  int displayWidth = (int) (width / zoom);  
  int k = values.length - displayWidth;  
  int x0 = 0;
  int y0 = getY(values[k]);

  for (int i=1; i<displayWidth; i++) {

    k++;
    int x1 = (int) (i * (width-1) / (displayWidth-1));
    int y1 = getY(values[k]);
    line(x0, y0, x1, y1);
    x0 = x1;
    y0 = y1;
  }
}

void drawGrid_old() {
  stroke(64, 0, 0);
  for (int i=1; i<5; i++) {
    line(0, (i * height / 5), width, (i * height / 5));
  }
}

void drawGrid() {
  float c = bg*0.75;
  stroke(64+c,c,c);
  for (int i=1; i<5; i++) {
    line(0, (i * height / 5), width, (i * height / 5));
  }
  if (zoom == 1) {
    for (int i=2; i<width; i++) {
      if (floor(t[i] / 1000) > floor(t[i-1] / 1000)) {
        line(i, 0, i, height);
      } 
    }
  }
}

void keyReleased() {

  switch (key) {

    case 'p':  // Change port
      port.stop();                     // Stop any existing port
      portNum = ++portNum % numPorts;  // Try another from the list
      port = new Serial(this, Serial.list()[portNum], 19200);
      break;
      
    case '+':  // ZOOM IN
      zoom *= 2.0f;
      if ( (int) (width / zoom) <= 1 )
        zoom /= 2.0f;
      println(zoom);
      break;

    case '-':  // ZOOM OUT
      zoom /= 2.0f;
      if (zoom < 1.0f)
        zoom *= 2.0f;
      println(zoom);
      break;

    case ' ':  // PAUSE
      halt = !halt;
      bg = halt?255:0;
      // Add a marker for pausing
      pushValue(halt?0:1023);  
      break;

    case 's':  // SAVE TEXT FILE
      selectOutput("Select a file to write to:", "saveDataFile");
      break;

    case 'i':  // INVERT BACKGROUND
      bg = 255 - bg;
      break;
      
    case 'c':  // COPY TO CLIPBOARD
      copyClip = true;

      /*
      int old_bg = bg;
      if (bg == 0) {  // invert to white background for screenshot
        bg = 255 - bg;
        draw();
      }
          
      print("start ");    
      //Thread.sleep(500);
      print("end ");
      
      new CopyImagetoClipBoard();

/*      if (old_bg == 0) {  // return to previous background
        bg = 255 - bg;
      }
*/
      break;

  }

}



void draw()
{
  if (copyClip) {
      if (bg == 0) {  // invert to white background for screenshot
        bg = 255 - bg;
      } else {
        new CopyImagetoClipBoard();
        copyClip = false;     
        bg = halt?255:0;
      }   
  }
  
  background(bg);
  fill(255-bg);
  drawGrid();
  val = getValue();

  if (val != -1 && !halt) {
    pushValue(val);

    // Display voltage
    textSize(24);
    text(nf(val / 1023.0f * 5.0f, 1, 3)+'V',width-100,40);
    
    //int ms = (int) System.currentTimeMillis() % 1000;
    timestamp = nf(year(),4)+'/'+nf(month(),2)+'/'+nf(day(),2)+' '+nf(hour(),2)+':'+nf(minute(),2)+":"+nf(second(),2);
  }

  drawLines();

  // add labels
  textSize(12);
  text("[+/-] Zoom time axis", 20, height-70);
  text("[space] Pause", 20, height-55);
  text("[p] Change USB port", 20, height-40);
  text("[s] Save data", 20, height-25);
  text("[c] Clipboard copy", 20, height-10);
  
  text(timestamp, 20, 30);
  text(System.getProperty("user.name"),20,45);
  textSize(8);
  text("["+Serial.list()[portNum]+"]",20,56);
  
//    if (old_bg == 0) {  // return to previous background
//        bg = 255 - bg;
//    }
    
}

void saveDataFile(File selection) {

  if (selection == null) {
    println("Save canceled.");
  } else {
    savefile = selection.getAbsolutePath();
    PrintWriter output = createWriter(savefile);
    for (int i=1; i<values.length; i++)
    
    output.println((t[i]-t[1])/1000.0f + ", " + nf(values[i] / 1023.0f * 5.0f, 1, 3));
    // Write the coordinate to the file

    output.flush();
    // Writes the remaining data to the file

    output.close();

    println("Data saved to:" + savefile);

  }

}
      
public class CopyImagetoClipBoard implements ClipboardOwner {
    public CopyImagetoClipBoard() {
        try {
            Robot robot = new Robot();
            java.awt.Point pt = getLocationOnScreen();
            Rectangle screen = new Rectangle( pt.x, pt.y, width, height );
            BufferedImage i = robot.createScreenCapture( screen );
            TransferableImage trans = new TransferableImage( i );
            Clipboard c = Toolkit.getDefaultToolkit().getSystemClipboard();
            c.setContents( trans, this );
        }
        catch ( AWTException x ) {
            x.printStackTrace();
            System.exit( 1 );
        }
    }

    public void lostOwnership( Clipboard clip, Transferable trans ) {
        System.out.println( "Lost Clipboard Ownership" );
    }

    private class TransferableImage implements Transferable {

        Image i;

        public TransferableImage( Image i ) {
            this.i = i;
        }

        public Object getTransferData( DataFlavor flavor )
        throws UnsupportedFlavorException, IOException {
            if ( flavor.equals( DataFlavor.imageFlavor ) && i != null ) {
                return i;
            }
            else {
                throw new UnsupportedFlavorException( flavor );
            }
        }

        public DataFlavor[] getTransferDataFlavors() {
            DataFlavor[] flavors = new DataFlavor[ 1 ];
            flavors[ 0 ] = DataFlavor.imageFlavor;
            return flavors;
        }

        public boolean isDataFlavorSupported( DataFlavor flavor ) {
            DataFlavor[] flavors = getTransferDataFlavors();
            for ( int i = 0; i < flavors.length; i++ ) {
                if ( flavor.equals( flavors[ i ] ) ) {
                    return true;
                }
            }

            return false;
        }
    }
}
