import javax.sound.sampled.*;
import java.io.*;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import javax.sound.sampled.AudioFileFormat;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;

double fs = 48000.;
double nyqf = fs/2;
int nbits = 16;
double f1 = 220.0, f2 = 2000.0;
int channels = 1;
double dur = 5.0;
byte[] pcm_data = new byte[(int)(fs*dur)];
AudioFormat frmt;
AudioInputStream ais;
String filename = "test.wav";
double amplitude = 1.0;
double twoPi = 2.*Math.PI;
double twoPiF = f1*twoPi;
int N = 16;
ArrayList<Float> buffer = new ArrayList<Float>();   // replace f with ft use .add() and .get()
ArrayList<Byte> byteBuffer= new ArrayList<Byte>();
boolean bigEndian = false;
boolean signed = true;
int nsamp = (int)(fs*dur);
String testMethod = "Swept Tone";

void setup() {
  if (testMethod == "Sine")
    generateSineWave();
  else if (testMethod == "Noise")
    generateWhiteNoise();
  else if (testMethod == "Swept Tone")
    generateSweepSine(f1,f2);
  else if (testMethod == "MLS")
    generateMLS(N);
  else{
    println("Define an available test signal as: Sine, Noise, Swept Tone or MLS");
    exit();
  }
  // Put signal in a byte stream 
  float2Byte();
  AudioInputStream audioInputStream = set4saving();
  saveAudioFile(audioInputStream, filename);
}

void draw() {}

void mousePressed() {
}

// The best way to synthesis a file with JavaSound
void generateSineWave() {
  println("Generating Sine wave signal...");
  // Generate signal
  for (int sample = 0; sample < nsamp; sample++) {
      double time = sample / fs;
      buffer.add((float) (amplitude * Math.sin(twoPiF * time)));
  }
}

void generateWhiteNoise() {
  println("Generating white noise...");
  // Generate signal
  double Max = amplitude;
  double Min = -amplitude;
  for (int sample = 0; sample < nsamp; sample++) {
      buffer.add((float) ((Math.random()*(Max-Min))-1.));
  }
}

void generateSweepSine(double f1, double f2){
  if (f1<1)
    f1 = 1;        // Avoid 0Hz
  else if (f2>f1)
    println("Generating Swept tone signal...");
  else{
    println("Error defining f1 and f2, f2 must be greater than f1");
    exit();
  }
  // convert to log2
  double b1 = log2(f1);
  double b2 = log2(f2);
  // define log2 range
  double rb = b2-b1;
  // defining step by time resolution
  double step = rb/nsamp;
  double nf = b1 ;   // new frequency
  for (int sample = 0; sample < nsamp; sample++) {
      double time = sample / fs;
      double f = Math.pow(2.,nf);
      buffer.add((float) (amplitude * Math.sin(twoPi* f * time)));
      nf = nf +step;
  }
}

void generateMLS(int N){
  println("Generating MLS signal...");
  // Initialize abuff array to ones
  // Generate pseudo random signal
  nsamp = (int)Math.pow(2,N);
  int taps=4, tap1=1, tap2=2, tap3=4, tap4=15;
  if (N!=16){
    println("At this moment MLS signal is only defined for 16 bits, soon other tap values will be included.");
    exit();
  }
  int[] abuff = new int[N];
  // fill with ones
  for (int i = 0; i<abuff.length;i++){
    abuff[i] = 1;
  }
  for(int i = (int) Math.pow(2.,N); i>1; i--){
    // feedback bit
    int xorbit = abuff[tap1] ^ abuff[tap2];
    // second logic level
    if (taps==4){
      int xorbit2 = abuff[tap3] ^ abuff[tap4]; //4 taps = 3 xor gates & 2 levels of logic
      xorbit = xorbit ^ xorbit2;        //second logic level
    }
    // Circular buffer
    for (int j= N-1; j>0; j--){
      int temp = abuff[j-1];
      abuff[j] = temp;
    }
    abuff[0] = xorbit;
    // fill sample value
    buffer.add((float)(-2 * xorbit) + 1);
  }
}

// Put signal in a byte stream
void float2Byte() {
  int bufferIndex = 0;
  println(buffer.size());
  while (bufferIndex<buffer.size()){
    final int x = (int) (buffer.get(bufferIndex++) * 32767.0);
    byteBuffer.add((byte) x);
    byteBuffer.add((byte) (x >>> 8));
  }
}

// Set format and byte buffer
AudioInputStream set4saving(){
  AudioFormat format = new AudioFormat((float)fs, nbits, channels, signed, bigEndian);
  byte[] result = new byte[byteBuffer.size()];
  for(int i = 0; i < byteBuffer.size(); i++) {
    result[i] = byteBuffer.get(i).byteValue();
  }
  ByteArrayInputStream bais = new ByteArrayInputStream(result);
  AudioInputStream audioInputStream = new AudioInputStream(bais, format,buffer.size());
  return audioInputStream;
}

/* Save audio input stream to audio file */
void saveAudioFile(AudioInputStream ais, String filename){
  try {
    AudioSystem.write(ais, AudioFileFormat.Type.WAVE, new File(filename));
    ais.close();
  } 
  catch(Exception e) {
    e.printStackTrace();
  }
}

/* Compute logarithm with base 2 */
double log2(double x){
  double res = Math.log10(x)/Math.log10(2.);
  return res;
}

/* 
TODO 
- include taps values for other bits resolution on MLS signal
- Implement Test Generator on Android and play signals.
- Apply DSP to get H(w) for Sweept tone and MLS 
- Results have to be shown on dynaton_LogGrid
- Start to works on WLAN communication
- Implement application on Java to communicate with myRoomie.
*/