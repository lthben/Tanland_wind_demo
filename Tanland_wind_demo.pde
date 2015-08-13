/*
Author: Benjamin Low (benjamin.low@digimagic.com.sg)
 Date: 13 Aug 2015
 Description: Demo for the wind sensor from Modern Devices. For Tanland heat wave 
installation. Input is the wind speed reading from Arduino connected to the sensor.
Raw reading is 330-500. Byte is 0-255. So the Arduino sends "raw_reading-300".
 */

import processing.serial.*;

Serial myPort;

//USER SENSITIVITY SETTINGS
float noise_threshold = 40; //strength of airflow that will trigger a positive detection reading. This is the value sent by Arduino.
float tolerance = 1.5; //multiplier for noise threshold. Constrains the actual readings. Affects response time greatly. A higher value means higher sensitivity.
int action_duration = 5;//approximate response time in seconds

//Other global variables
int num_readings = action_duration * 60; //assuming frameRate of 60
float reading_total, reading_average;
float[] readings;
int read_index;

boolean is_triggered;
long time_triggered;

PFont font;

void setup()
{
    size(displayWidth, displayHeight);

    rectMode(CORNERS);
    font = loadFont("ArialMT-12.vlw");

    readings = new float[num_readings];
    
    println(Serial.list());
    myPort = new Serial(this, "/dev/cu.usbmodem1411", 9600);
}


void draw()
{
          int inByte = 0;
      
        while (myPort.available() > 0) {
            inByte = myPort.read();
            println(inByte);
    }
        
        
        
    if (millis() - time_triggered < action_duration*1000 && is_triggered) {
        background(25, 0, 128);
        fill(255,0,0);
        textSize(160);
        textAlign(CENTER, CENTER);
        text("TRIGGERED", width/2, height/2);
    } else {
        fill(255);
        background(0);
    }


    noStroke();


    if (millis() - time_triggered > action_duration*1000 || !is_triggered) {
        
            float actual_reading = float(inByte);
        
        readings[read_index] = constrain(actual_reading, 0.0, tolerance*noise_threshold); 
        reading_total += readings[read_index];
        int index_oldest = (read_index + 1)%num_readings;
        reading_total -= readings[index_oldest];
        read_index++;

        if (read_index == num_readings) {
            read_index = 0;
        }    

        reading_average = reading_total/num_readings;
        
        fill(255,255,0);
        rect(0, height/3, (reading_average/noise_threshold)*width, height*2/3);
        
        if (actual_reading > noise_threshold) text("above noise reading: " + actual_reading, 0.1*width, 0.7*height);  
    } 

    if (reading_average > noise_threshold) {
        is_triggered = true;
        time_triggered = millis();
        reading_total = 0;
        reading_average = 0;
        for (int i=0; i<num_readings; i++) {
            readings[i] = 0;
        }        
    } else if (millis() - time_triggered > action_duration*1000) {
        is_triggered = false;
    }
    
    fill(255);
    textSize(24);
    textAlign(LEFT, CENTER);
    text("noise threshold: " + noise_threshold, 0.1*width, 0.8*height);
    text("tolerance: " + tolerance, 0.4*width, 0.8*height);
    text("response time: " + action_duration, 0.6*width, 0.8*height);
    text("reading average: " + reading_average, 0.1*width, 0.9*height);
}

boolean sketchFullScreen() {
  return true;
}
