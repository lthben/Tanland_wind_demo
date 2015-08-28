/*
 Author: Benjamin Low (benjamin.low@digimagic.com.sg)
 Last update: 28 Aug 2015
 Description: Demo for the wind sensor from Modern Devices. For Tanland heat wave 
 installation. Input is the wind speed reading from Arduino connected to the sensor.
 Assumes raw reading from Arduino is 330-500 and that Arduino sends "raw_reading-300".
 Note that the Nyquist sampling theorem must hold for this to work. This Processing
 sketch must sample at more than twice the frequency of the data being sent from
 Arduino.
 */

import processing.serial.*;

Serial myPort;

//USER SETTINGS in settings.txt in data folder
String my_serial_port;
float noise_threshold; //strength of airflow that will trigger a positive detection reading. This is the value sent by Arduino.
float tolerance; //multiplier for noise threshold. Constrains the actual readings. Affects response time greatly. A higher value means higher sensitivity.
int action_duration;//approximate response time in seconds

//for reading the text file
String[] lines;
int line_index;

//Other global variables
int num_readings; 
float reading_total, reading_average;
float[] readings;
int read_index;
String in_string;

boolean is_triggered;
long time_triggered;

void setup()
{
        size(640, 480);
        
        printArray(Serial.list());
        
        lines = loadStrings("settings.txt");
        
        if (line_index < lines.length) {
                 String[] first_line = split(lines[0], '=');
                 my_serial_port = first_line[1];    
                 println("SERIAL PORT=" + my_serial_port);
                 String[] second_line = split(lines[1], '=');
                 noise_threshold = float(second_line[1]);
                 println("NOISE_THRESHOLD=" + noise_threshold);
                 String[] third_line = split(lines[2], '=');
                 tolerance = float(third_line[1]);
                 println("TOLERANCE=" + tolerance);
                 String[] fourth_line = split(lines[3], '=');
                 action_duration = int(fourth_line[1]);
                 println("ACTION_DURATION=" + action_duration);
        }

        rectMode(CORNERS);
        
        num_readings = action_duration * 60; //assuming frameRate of 60
        readings = new float[num_readings];
        
        myPort = new Serial(this, my_serial_port, 9600);
}


void draw()
{

       while (myPort.available () > 0) {
                String string_buffer = myPort.readStringUntil(10);

                if (string_buffer != null) {
                        in_string = trim(string_buffer);
//                        println(in_string);
                }
        }



        if (millis() - time_triggered < action_duration*1000 && is_triggered) {
                background(25, 0, 128);
                fill(255, 0, 0);
                textSize(width/10);
                textAlign(CENTER, CENTER);
                text("TRIGGERED", width/2, height/2);
        } else {
                fill(255);
                background(0);
        }


        noStroke();


        if (millis() - time_triggered > action_duration*1000 || !is_triggered) {

                float actual_reading = float(in_string);

                readings[read_index] = constrain(actual_reading, 0.0, tolerance*noise_threshold); 
                reading_total += readings[read_index];
                int index_oldest = (read_index + 1)%num_readings;
                reading_total -= readings[index_oldest];
                read_index++;

                if (read_index == num_readings) {
                        read_index = 0;
                }    

                reading_average = reading_total/num_readings;

                fill(255, 255, 0);
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
        textSize(width/40);
        textAlign(LEFT, CENTER);
        text("noise threshold: " + noise_threshold, 0.1*width, 0.8*height);
        text("tolerance: " + tolerance, 0.4*width, 0.8*height);
        text("response time: " + action_duration, 0.6*width, 0.8*height);
        text("reading average: " + reading_average, 0.1*width, 0.9*height);
}

boolean sketchFullScreen() {
        return false;
}

