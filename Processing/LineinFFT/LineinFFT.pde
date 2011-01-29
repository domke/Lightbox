/**
  * This sketch demonstrates how to use an FFT (Fast Fourier Transform) to analyze an
  * AudioBuffer and draw the resulting spectrum. <br />
  * It also allows you to turn windowing on and off,
  * but you will see there is not much difference in the spectrum.<br />
  * Press 'w' to turn on windowing, press 'e' to turn it off.
  */
 
import ddf.minim.analysis.*;
import ddf.minim.*;
import controlP5.*;
ControlP5 controlP5;

import processing.serial.*;
Serial myPort;
Slider sliderGain;
Minim minim;
AudioInput in;
FFT fft;
String windowName;
 
//bangs are used to simulate the lightboxes
Bang[] bang = new Bang[255];

boolean slomotion = false;

int NETWORK_SIZE = 6;
 
float gain = 15.0;
 
void setup()
{
  size(512, 400);
//    size(512, 200, P3D);
//  textMode(SCREEN);
  frameRate(25);
 
  minim = new Minim(this);
 
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.STEREO, 512);
 
  // create an FFT object that has a time-domain buffer 
  // the same size as jingle's sample buffer
  // note that this needs to be a power of two 
  // and that it means the size of the spectrum
  // will be 512. see the online tutorial for more info.
  fft = new FFT(in.bufferSize(), in.sampleRate());
 
  textFont(createFont("Arial", 16));
 
  windowName = "None";
  
  controlP5 = new ControlP5(this);
  for(int i=0; i < NETWORK_SIZE; i++){ 
    bang[i] = controlP5.addBang("bang" + i,300 + (i*25), 5,20,20);
    bang[i].setId(i);
    bang[i].setCaptionLabel(""+i);
    bang[i].setColorForeground(0);
  }
  /*sliderGain = controlP5.addSlider("sliderGain",0,500,1, 50,50,200,20);
  gain=(float)sliderGain.value();*/
  // open RS232 Port
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 57600);
}
 
 
int[] output = new int[13];
  
void draw()
{
  background(0);
  stroke(255);
  // perform a forward FFT on the samples in jingle's left buffer
  // note that if jingle were a MONO file, 
  // this would be the same as using jingle.right or jingle.left
  fft.forward(in.mix);
    
  int outi=0;
  int slotsize = fft.specSize() / output.length;
  int value;
  
  if (!slomotion) {
   for(int i=0; i < output.length; i++)
      output[i] = 0; 
  }
  
  boolean shrinkValue = false;
  
  maxValue = 0; // reset the global variable
  for(int i = 0; i < fft.specSize(); i += 1) // shrink spectrum, and use only 80% of the spectrum
  {
    stroke(255);
    
    value = (int) (fft.getBand(i) * 3);
    line(i, height, i, height - value);
    
    if (i > 0 && i % slotsize == 0) {
      // draw a horizontal line for each slot
      stroke(color(255,0,0));
      line(outi * slotsize, height - output[outi], (outi + 1) * slotsize, height - output[outi]);
      
      if (slomotion) { // only modify the item once
        if (shrinkValue)
          output[outi] -= 2; // fade slowly to the bottom 
      }
      
      shrinkValue = false;
      outi++;    // use the next slot
      if (outi >= output.length)
        outi = output.length - 1;
    }
    
    if (slomotion) {
       if (value < output[outi])
          shrinkValue=true;
       else
         output[outi] = value;
    } else {
      output[outi] = max(output[outi],  value);
    }
    maxValue = max(maxValue, value);
  }
  
  // Display the combined values
  //RGB
  float x0=0.05;
  float x2=0.5;
  float x4=3;
  float x6=10;
  float x8=10;
  float x10=20;
  float x12=40;
  int y1=50;
  int y2=50;
  int y3=50;
  int y4=50;
  sendPWMCommandToLightBox(0, int(magic(output[0])*x0), 0,   0);
  sendPWMCommandToLightBox(0, int((magic(output[2])*x2*y1)/100), int((magic(output[2])*x2*y2)/100),  1);
  sendPWMCommandToLightBox(0, 0, int(magic(output[4])*x4), 2);
  sendPWMCommandToLightBox(0, 0, int(magic(output[8])*x8), 3);
  sendPWMCommandToLightBox(int((magic(output[10])*x10*y3)/100), int((magic(output[10])*x10*y4)/100), 0, 4);
  sendPWMCommandToLightBox(int(magic(output[12])*x12), 0, 0, 5);
    
  fill(255);
  // keep us informed about the window being used
  text("The window being used is: " + windowName, 5, 20);
}
 
void keyReleased()
{
  if ( key == 'w' )
  {
    // a Hamming window can be used to shape the sample buffer that is passed to the FFT
    // this can reduce the amount of noise in the spectrum
    fft.window(FFT.HAMMING);
    windowName = "Hamming";
  }
 
  if ( key == 'e' )
  {
    fft.window(FFT.NONE);
    windowName = "None";
  }
  
  if ( key == 's' )
  {
     slomotion = !slomotion; 
     if (slomotion)
       windowName = "Slomotion activated";
     else
       windowName = "";
  }
}
 
void stop()
{
  // always close Minim audio classes when you finish with them
  in.close();
  minim.stop();
 
  super.stop();
}

synchronized void sendPWMCommandToLightBox(int r, int g, int b, int id){
  bang[id].setColorForeground(color(r,g,b));
  String command = "pw";
  command += hex(r,2);
  command += hex(g,2);
  command += hex(b,2);
  command += hex(id,2);
  command += "o";
  sendStringCommandToLightBox(command);
}

synchronized void sendStringCommandToLightBox(String cmd) {
  myPort.write(cmd);
  println(cmd);
}

int maxValue;

int magic(int number) {
//  return (int) (255.0 * number / maxValue);  
  return (int) (number*gain); // No Magic no longer
}
