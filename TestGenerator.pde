
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
double f1 = 440.0, f2 = 1000.0;
int channels = 1;
double dur = 2.0;
byte[] pcm_data = new byte[(int)(fs*dur)];
AudioFormat frmt;
AudioInputStream ais;
String filename = "test.wav";
double amplitude = 1.0;
double twoPi = 2.*Math.PI;
double twoPiF = f1*twoPi;
float[] buffer = new float[(int) (dur * fs)];
byte[] byteBuffer = new byte[buffer.length * (int)dur];
boolean bigEndian = false;
boolean signed = true;
int nsamp = (int)(fs*dur);

void setup() {
  //generateSineWave();
  //generateWhiteNoise();
  //generateSweepSine(f1,f2);
  generateMLS(4);
  // Put signal in a byte stream 
  float2Byte();
  AudioInputStream audioInputStream = set4saving();
  saveAudioFile(audioInputStream, filename);
}

void draw() {}

void mousePressed() {
  //generateSineWave2();
}

// The best way to synthesis a file with JavaSound
void generateSineWave() {
  // Generate signal
  for (int sample = 0; sample < buffer.length; sample++) {
      double time = sample / fs;
      buffer[sample] = (float) (amplitude * Math.sin(twoPiF * time));
  }
}

void generateWhiteNoise() {
  // Generate signal
  double Max = amplitude;
  double Min = -amplitude;
  for (int sample = 0; sample < buffer.length; sample++) {
      buffer[sample] = (float) ((Math.random()*(Max-Min))-1.);
  }
}

void generateSweepSine(double f1, double f2){
  //f1 = f1+epsilon; // avoiding 0 frequency
  // convert to log2
  double b1 = log2(f1);
  double b2 = log2(f2);
  // define log2 range
  double rb = b2-b1;
  // defining step by time resolution
  double step = rb/nsamp;
  double nf = b1 ;   // new frequency
  for (int sample = 0; sample < buffer.length; sample++) {
      double time = sample / fs;
      double f = Math.pow(2.,nf);
      buffer[sample] = (float) (amplitude * Math.sin(twoPi* f * time));
      nf = nf +step;
  }
}

void generateMLS(int N){
  // Initialize abuff array to ones
  // Generate pseudo random signal
   int taps=4, tap1=2, tap2=3, tap3=5, tap4=16;
   int[] abuff = new int[N];
   // fill with ones
   for (int i = 0; i<abuff.length;i++){
     abuff[i] = 1;
   }
   for(int i = (int) Math.pow(2.,N); i>1; i--){
     // feedback bit
     //boolean xorbit = ((abuff[tap1]) != (abuff[tap2]));
     int xorbit = abuff[tap1] ^ abuff[tap2];
     println(xorbit);
     // second logic level
     if (taps==4){
      int xorbit2 = abuff[tap3] ^ abuff[tap4]; //4 taps = 3 xor gates & 2 levels of logic
      xorbit = xorbit ^ xorbit2;        //second logic level
     }
     // Circular buffer
     for (int j= N-1; j>0; j++){
       int temp = abuff[j-1];
       abuff[j] = temp;
     }
     
     // Evaluate if the last if is correct, it should move the array one position
     // like this abuff = [xorbit abuff(1:n-1)];
     abuff[0] = xorbit;
     y[i] = (-2 * xorbit) + 1;
   }
}

// Put signal in a byte stream
void float2Byte() {
  int bufferIndex = 0;
  for (int i = 0; i < byteBuffer.length; i++) {
    final int x = (int) (buffer[bufferIndex++] * 32767.0);
    byteBuffer[i] = (byte) x;
    i++;
    byteBuffer[i] = (byte) (x >>> 8);
  }
}

// Set format and byte buffer
AudioInputStream set4saving(){
  AudioFormat format = new AudioFormat((float)fs, nbits, channels, signed, bigEndian);
  ByteArrayInputStream bais = new ByteArrayInputStream(byteBuffer);
  AudioInputStream audioInputStream = new AudioInputStream(bais, format,buffer.length);
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

double log2(double x){
  double res = Math.log10(x)/Math.log10(2.);
 return res;
}