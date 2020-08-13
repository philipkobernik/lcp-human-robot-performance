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
    * input `npm run start` and press enter
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
    * navigate into `lcp_sim`
    * double click the `lcp_sim.pdf` file
    * click the play button to start the sketch


4. start the posenet tracker
    * open [posenet camera tracker](https://lcp-posenet.surge.sh/camera.html)
      * algorithm: `single-pose`
      * architecture: `MobileNetv1`
      * input resolution: `250` or `300`


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
