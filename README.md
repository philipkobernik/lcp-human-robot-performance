# lcp-human-robot-performance

This repo contains source code for multiple applications involved in the capture of pose data, transmission of pose data across the internet, and transforming pose data into instructions for the LCP.

![system diagram](https://raw.githubusercontent.com/philipkobernik/lcp-human-robot-performance/main/system-diagram-1.png)

## repo contents

### lcp_posenet
Source code for the posenet motion capture system. node and yarn are used to develop and compile into static web pages.

### firebase_osc_relay
Source code for a tiny node script. Acts as a firebase client and relays firebase data into OSC messages on the localhost. node and npm are used to develop and run this client/server application in the terminal.

### lcp_sim
Source code for the LCP simulator. Processing sketch.

### mapping_prototypes
I imagine we will build multiple mapping prototypes as we investigate. Let us document all of them.

### testing_utilities
Generators, calibration routines should live in here.

## instructions for startup once software is installed
(assumes repo is cloned into home folder `~/`)

1. start firebase_osc_relay:
    * press command-key + spacebar, type in `terminal`, press enter
    * input `cd ~/lcp-human-robot-performance/firebase_osc_relay/` and press enter
    * input `npm run start [userId]` and press enter
        * for example, brooke would input `npm run start brooke`
    * terminal should say
        * `relaying pose data from firebase to localhost:10419 ...`


2. start one of the mapping prototype:
    * open finder
    * click `lcp-human-robot-performance` under favorites bar
    * navigate into `mapping_prototypes`
    * navigate into one of the prototypes, like `body_as_cursor`
    * double click the `body_as_cursor.pde` file
    * click the play button to start the sketch


3. start the LCP simulator
    * open finder
    * click `lcp-human-robot-performance` under favorites bar
    * navigate into `simulation_prototypes > lcp_sim`
    * double click the `lcp_sim.pdf` file
    * click the play button to start the sketch
    
4. start the audio tracker
    * open [LCP Audio Tracker](https://lcp-audio.surge.sh/)
    * click "Open Microphone" and accept the access prompt from the browser
    * test it by snapping, or clapping. the goal is for your sound to cause one trigger, not multiple. short sounds like clap or snap work better than voice. Adjust the threshold if it is too sensitive, or not sensitive enough.
    * once you have tested the audio trigger, make sure that your browser's "selected" tab is the lcp-posenet one-- otherwise the camera will turn off after a short time

4. start the posenet tracker
    * open [posenet camera tracker](https://lcp-posenet.surge.sh/camera.html)
        * architecture: `MobileNetv1`
            * use `ResNet50` if you have a newer computer or discrete GPU
        * input resolution: `250` or `300`
        * make sure to intialize the tracker with your `userId`. This can be your first name or a codename. When you save sequences, they will be saved under this `userId`.


## instructions for getting updates to the codebase
1. stop running programs:
    * if `firebase_osc_relay` is running, focus on that terminal window, then press `control`+`c`
    * if any processing sketches are running, click the "stop" button to stop them


2. navigate to the folder in terminal:
    * press command-key + spacebar, type in `terminal`, press enter
    * input `cd ~/lcp-human-robot-performance` and press enter


3. pull in the new code changes
    * input `git pull origin main` and press enter


4. now you can restart `firebase_osc_relay` and and your processing sketches
