# lcp-human-robot-performance

This repo contains source code for multiple applications involved in the capture of pose data, transmission of pose data across the internet, and transforming pose data into instructions for the LCP.

![system diagram](https://raw.githubusercontent.com/philipkobernik/lcp-human-robot-performance/main/system-diagram-1.png)

## lcp_posenet
Source code for the posenet motion capture system. node and yarn are used to develop and compile into static web pages.

## firebase_osc_relay
Source code for a tiny node script. Acts as a firebase client and relays firebase data into OSC messages on the localhost. node and npm are used to develop and run this client/server application in the terminal.

## lcp_sim
Source code for the LCP simulator. Processing sketch.

## mapping_prototypes
I imagine we will build multiple mapping prototypes as we investigate. Let us document all of them.

## testing_utilities
Generators, experimental renderers, calibration routines, and perhaps more nonsense should live in here.
