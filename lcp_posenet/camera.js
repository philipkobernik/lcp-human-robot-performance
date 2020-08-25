/**
 * @license
 * Copyright 2019 Google LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 */
import * as posenet from '@tensorflow-models/posenet';
import dat from 'dat.gui';
import Stats from 'stats.js';

import {drawBoundingBox, drawKeypoints, drawSkeleton, isMobile, toggleLoadingUI, tryResNetButtonName, tryResNetButtonText, updateTryResNetButtonDatGuiCss} from './demo_util';

import * as firebase from "firebase/app";
import 'firebase/database';
import db from './firebaseInit'

// Add the Firebase services that you want to use
import "firebase/auth";
import "firebase/firestore";

const videoWidth = 600;
const videoHeight = 500;
const stats = new Stats();

let frameCountDisplayController = null;

Date.prototype.toIsoString = function() {
    var tzo = -this.getTimezoneOffset(),
        dif = tzo >= 0 ? '+' : '-',
        pad = function(num) {
            var norm = Math.floor(Math.abs(num));
            return (norm < 10 ? '0' : '') + norm;
        };
    return this.getFullYear() +
        '-' + pad(this.getMonth() + 1) +
        '-' + pad(this.getDate()) +
        'T' + pad(this.getHours()) +
        ':' + pad(this.getMinutes()) +
        ':' + pad(this.getSeconds()) +
        dif + pad(tzo / 60) +
        ':' + pad(tzo % 60);
}

/**
 * Loads a the camera to be used in the demo
 *
 */
async function setupCamera() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    throw new Error(
        'Browser API navigator.mediaDevices.getUserMedia not available');
  }

  const video = document.getElementById('video');
  video.width = videoWidth;
  video.height = videoHeight;

  const mobile = isMobile();
  const stream = await navigator.mediaDevices.getUserMedia({
    'audio': false,
    'video': {
      facingMode: 'user',
      width: mobile ? undefined : videoWidth,
      height: mobile ? undefined : videoHeight,
    },
  });
  video.srcObject = stream;

  return new Promise((resolve) => {
    video.onloadedmetadata = () => {
      resolve(video);
    };
  });
}

async function loadVideo() {
  const video = await setupCamera();
  video.play();

  return video;
}

const defaultQuantBytes = 2;

const defaultMobileNetMultiplier = isMobile() ? 0.50 : 0.75;
const defaultMobileNetStride = 16;
const defaultMobileNetInputResolution = 500;

const defaultResNetMultiplier = 1.0;
const defaultResNetStride = 32;
const defaultResNetInputResolution = 250;

const guiState = {
  algorithm: 'single-pose',
  input: {
    architecture: 'MobileNetV1',
    outputStride: defaultMobileNetStride,
    inputResolution: defaultMobileNetInputResolution,
    multiplier: defaultMobileNetMultiplier,
    quantBytes: defaultQuantBytes
  },
  singlePoseDetection: {
    minPoseConfidence: 0.1,
    minPartConfidence: 0.5,
  },
  multiPoseDetection: {
    maxPoseDetections: 5,
    minPoseConfidence: 0.15,
    minPartConfidence: 0.1,
    nmsRadius: 30.0,
  },
  output: {
    showVideo: true,
    showSkeleton: true,
    showPoints: true,
    showBoundingBox: false,
  },
  user: {
    id: "",
  },
  tapeDeck: {
    playing: false,
    recording: false,
    frameCountDisplay: 0,
    storeTape: false,
    newTapeName: "",
  },
  saved: {
    list: {
      0: 'zero'
    }
  },
  net: null,
  sequence: [],
  frameCounter: 0,
  userId: 'default'
};

/**
 * Sets up dat.gui controller on the top-right of the window
 */
function setupGui(cameras, net) {
  guiState.net = net;

  if (cameras.length > 0) {
    guiState.camera = cameras[0].deviceId;
  }

  const gui = new dat.GUI({width: 300});

  let tapesFolder = null; // using tapesFolder as a sort-of global state for this gui lib
  // its pretty gross, but its working
  // when I list tapes, I blow away this "folder" and re-create it, so need to keep a reference

  let userTapesRef = null;

  let architectureController = null;
  let userIdController = null;

  // The input parameters have the most effect on accuracy and speed of the
  // network
  let input = gui.addFolder('Input');
  // Architecture: there are a few PoseNet models varying in size and
  // accuracy. 1.01 is the largest, but will be the slowest. 0.50 is the
  // fastest, but least accurate.
  architectureController =
      input.add(guiState.input, 'architecture', ['MobileNetV1', 'ResNet50']);
  guiState.architecture = guiState.input.architecture;
  // Input resolution:  Internally, this parameter affects the height and width
  // of the layers in the neural network. The higher the value of the input
  // resolution the better the accuracy but slower the speed.
  let inputResolutionController = null;
  function updateGuiInputResolution(
      inputResolution,
      inputResolutionArray,
  ) {
    if (inputResolutionController) {
      inputResolutionController.remove();
    }
    guiState.inputResolution = inputResolution;
    guiState.input.inputResolution = inputResolution;
    inputResolutionController =
        input.add(guiState.input, 'inputResolution', inputResolutionArray);
    inputResolutionController.onChange(function(inputResolution) {
      guiState.changeToInputResolution = inputResolution;
    });
  }

  // Output stride:  Internally, this parameter affects the height and width of
  // the layers in the neural network. The lower the value of the output stride
  // the higher the accuracy but slower the speed, the higher the value the
  // faster the speed but lower the accuracy.
  let outputStrideController = null;
  function updateGuiOutputStride(outputStride, outputStrideArray) {
    if (outputStrideController) {
      outputStrideController.remove();
    }
    guiState.outputStride = outputStride;
    guiState.input.outputStride = outputStride;
    outputStrideController =
        input.add(guiState.input, 'outputStride', outputStrideArray);
    outputStrideController.onChange(function(outputStride) {
      guiState.changeToOutputStride = outputStride;
    });
  }

  // Multiplier: this parameter affects the number of feature map channels in
  // the MobileNet. The higher the value, the higher the accuracy but slower the
  // speed, the lower the value the faster the speed but lower the accuracy.
  let multiplierController = null;
  function updateGuiMultiplier(multiplier, multiplierArray) {
    if (multiplierController) {
      multiplierController.remove();
    }
    guiState.multiplier = multiplier;
    guiState.input.multiplier = multiplier;
    multiplierController =
        input.add(guiState.input, 'multiplier', multiplierArray);
    multiplierController.onChange(function(multiplier) {
      guiState.changeToMultiplier = multiplier;
    });
  }

  // QuantBytes: this parameter affects weight quantization in the ResNet50
  // model. The available options are 1 byte, 2 bytes, and 4 bytes. The higher
  // the value, the larger the model size and thus the longer the loading time,
  // the lower the value, the shorter the loading time but lower the accuracy.
  let quantBytesController = null;
  function updateGuiQuantBytes(quantBytes, quantBytesArray) {
    if (quantBytesController) {
      quantBytesController.remove();
    }
    guiState.quantBytes = +quantBytes;
    guiState.input.quantBytes = +quantBytes;
    quantBytesController =
        input.add(guiState.input, 'quantBytes', quantBytesArray);
    quantBytesController.onChange(function(quantBytes) {
      guiState.changeToQuantBytes = +quantBytes;
    });
  }

  function updateGui() {
    if (guiState.input.architecture === 'MobileNetV1') {
      updateGuiInputResolution(
          defaultMobileNetInputResolution,
          [200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800]);
      updateGuiOutputStride(defaultMobileNetStride, [8, 16]);
      updateGuiMultiplier(defaultMobileNetMultiplier, [0.50, 0.75, 1.0]);
    } else {  // guiState.input.architecture === "ResNet50"
      updateGuiInputResolution(
          defaultResNetInputResolution,
          [200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800]);
      updateGuiOutputStride(defaultResNetStride, [32, 16]);
      updateGuiMultiplier(defaultResNetMultiplier, [1.0]);
    }
    updateGuiQuantBytes(defaultQuantBytes, [1, 2, 4]);
  }

  updateGui();
  input.open();
  // Pose confidence: the overall confidence in the estimation of a person's
  // pose (i.e. a person detected in a frame)
  // Min part confidence: the confidence that a particular estimated keypoint
  // position is accurate (i.e. the elbow's position)
  let single = gui.addFolder('Single Pose Detection');
  single.add(guiState.singlePoseDetection, 'minPoseConfidence', 0.0, 1.0);
  single.add(guiState.singlePoseDetection, 'minPartConfidence', 0.0, 1.0);
  single.open();

  let output = gui.addFolder('Output');
  output.add(guiState.output, 'showVideo');
  output.add(guiState.output, 'showSkeleton');
  output.add(guiState.output, 'showPoints');
  output.add(guiState.output, 'showBoundingBox');
  output.open();

  let userFolder = gui.addFolder('User');
  userIdController = userFolder.add(guiState.user, "id");
  userFolder.open();

  let tapeDeck = gui.addFolder('Tape Deck');
  const playingController = tapeDeck.add(guiState.tapeDeck, 'playing');
  const recordingController = tapeDeck.add(guiState.tapeDeck, 'recording');
  frameCountDisplayController = tapeDeck.add(guiState.tapeDeck, 'frameCountDisplay');
  const newTapeNameController = tapeDeck.add(guiState.tapeDeck, "newTapeName");
  const storeTapeController = tapeDeck.add(guiState.tapeDeck, "storeTape");

  tapeDeck.open();

  architectureController.onChange(function(architecture) { 
    // if architecture is ResNet50, then show ResNet50 options
    updateGui();
    guiState.changeToArchitecture = architecture;
  });

  recordingController.onChange(function(value) {
    switch (guiState.tapeDeck.recording) {
      case true:
        // rec start
        guiState.sequence = [];
        guiState.frameCounter = 0;
        playingController.setValue(false);
        break;
      case false:
        guiState.output.frameCounter = 0;
        // rec stop! make it play!
        guiState.tapeDeck.playing = true;
        playingController.setValue(true);
        break;
    }
  });

  playingController.onChange(function(value) {
    switch (guiState.tapeDeck.playing) {
      case true:
        // play from the start
        guiState.frameCounter = 0;
        break
      case false:
        // stop playing
        break;
    }
  });

  storeTapeController.onChange(function(value) {
    if (guiState.user.id === "" || guiState.tapeDeck.newTapeName === "") return false;
    

    let blocked = false;
    let promises = [];

    var tapesRef = db.ref('users/' + guiState.userId + '/tapes');
    tapesRef
      .once('value')
      .then(function (snapshot) {
        snapshot.forEach(childSnapshot => {
          var childKey = childSnapshot.key;

          promises.push(db.ref(`saved/${childKey}`)
            .once('value')
            .then(function (snapshot) {
              let tape = snapshot.val();
              if (guiState.tapeDeck.newTapeName === tape.name) {
                // sameName
                blocked = true;
              }

            })
          )
        }); // end forEach
        return Promise.all(promises);
    })
    .then(snapshot => {
      console.log('blocked is', blocked)
      if (!blocked) {
        var newTapeRef = db.ref("saved").push();
        newTapeRef.set({
          created_at: new Date().toIsoString(),
          user: guiState.user.id,
          name: guiState.tapeDeck.newTapeName,
          sequence: guiState.sequence,
          length: guiState.sequence.length
        });
        db.ref(`users/${guiState.user.id}/tapes/${newTapeRef.key}`).set(true);
        console.log("setting to false", storeTapeController.domElement.children[-2]);
        storeTapeController.domElement.children[0].checked = false;
        console.log('stored');
        return true;
      } else {
        console.log("blocked!");
        return true;
      }
    });

  });

  newTapeNameController.onFinishChange(function(value) {
    guiState.newTapeName = value;
  })

  userIdController.onFinishChange((value) => {
    guiState.userId = value;

    if(userTapesRef) userTapesRef.off(); // remove user tapes listeners

    // blow away dat.gui list
    try {
      tapesFolder = gui.addFolder('Tapes');
    }
    catch (err) {
      gui.removeFolder(tapesFolder);
      tapesFolder = gui.addFolder('Tapes');
    }

    // rebind listeners to new ref
    setupUserTapesListeners(userTapesRef, tapesFolder, playingController);

    // open the folder
    tapesFolder.open();
    
  });

  // setupUserTapesListeners(userTapesRef, tapesFolder);
  // enable this if we add a default channel/user

}

function setupUserTapesListeners(ref, tapesFolder, playingController) {
  ref = db.ref(`users/${guiState.userId}/tapes`);

  ref.on('child_added', added => {
    var childKey = added.key;
    db.ref(`saved/${childKey}`)
      .once('value', function (snapshot) {
        let tape = snapshot.val();
        let name = `${tape.name}_${tape.length}`;
        guiState.saved.list[name] = false;
        const controller = tapesFolder.add(guiState.saved.list, name);

        let handler = (ctr, event) => {
          console.log(tape.name);
          guiState.sequence = tape.sequence;
          playingController.setValue(true);
          playingController.updateDisplay();
          // tries to uncheck the checkbox -- not sure why this doesn't work 
          controller.domElement.children[0].checked = false;
          return false;
        };

        controller.onChange(handler.bind(tape))
      })
      
  });

  ref.on('child_removed', snapshot => {
    console.log('removed');
  });
}

/**
 * Sets up a frames per second panel on the top-left of the window
 */
function setupFPS() {
  stats.showPanel(0);  // 0: fps, 1: ms, 2: mb, 3+: custom
  document.getElementById('main').appendChild(stats.dom);
}

/**
 * Feeds an image to posenet to estimate poses - this is where the magic
 * happens. This function loops with a requestAnimationFrame method.
 */
function detectPoseInRealTime(video, net) {
  const canvas = document.getElementById('output');
  const ctx = canvas.getContext('2d');

  // since images are being fed from a webcam, we want to feed in the
  // original image and then just flip the keypoints' x coordinates. If instead
  // we flip the image, then correcting left-right keypoint pairs requires a
  // permutation on all the keypoints.
  const flipPoseHorizontal = true;

  canvas.width = videoWidth;
  canvas.height = videoHeight;

  async function poseDetectionFrame() {
    if (guiState.changeToArchitecture) {
      // Important to purge variables and free up GPU memory
      guiState.net.dispose();
      toggleLoadingUI(true);
      guiState.net = await posenet.load({
        architecture: guiState.changeToArchitecture,
        outputStride: guiState.outputStride,
        inputResolution: guiState.inputResolution,
        multiplier: guiState.multiplier,
      });
      toggleLoadingUI(false);
      guiState.architecture = guiState.changeToArchitecture;
      guiState.changeToArchitecture = null;
    }

    if (guiState.changeToMultiplier) {
      guiState.net.dispose();
      toggleLoadingUI(true);
      guiState.net = await posenet.load({
        architecture: guiState.architecture,
        outputStride: guiState.outputStride,
        inputResolution: guiState.inputResolution,
        multiplier: +guiState.changeToMultiplier,
        quantBytes: guiState.quantBytes
      });
      toggleLoadingUI(false);
      guiState.multiplier = +guiState.changeToMultiplier;
      guiState.changeToMultiplier = null;
    }

    if (guiState.changeToOutputStride) {
      // Important to purge variables and free up GPU memory
      guiState.net.dispose();
      toggleLoadingUI(true);
      guiState.net = await posenet.load({
        architecture: guiState.architecture,
        outputStride: +guiState.changeToOutputStride,
        inputResolution: guiState.inputResolution,
        multiplier: guiState.multiplier,
        quantBytes: guiState.quantBytes
      });
      toggleLoadingUI(false);
      guiState.outputStride = +guiState.changeToOutputStride;
      guiState.changeToOutputStride = null;
    }

    if (guiState.changeToInputResolution) {
      // Important to purge variables and free up GPU memory
      guiState.net.dispose();
      toggleLoadingUI(true);
      guiState.net = await posenet.load({
        architecture: guiState.architecture,
        outputStride: guiState.outputStride,
        inputResolution: +guiState.changeToInputResolution,
        multiplier: guiState.multiplier,
        quantBytes: guiState.quantBytes
      });
      toggleLoadingUI(false);
      guiState.inputResolution = +guiState.changeToInputResolution;
      guiState.changeToInputResolution = null;
    }

    if (guiState.changeToQuantBytes) {
      // Important to purge variables and free up GPU memory
      guiState.net.dispose();
      toggleLoadingUI(true);
      guiState.net = await posenet.load({
        architecture: guiState.architecture,
        outputStride: guiState.outputStride,
        inputResolution: guiState.inputResolution,
        multiplier: guiState.multiplier,
        quantBytes: guiState.changeToQuantBytes
      });
      toggleLoadingUI(false);
      guiState.quantBytes = guiState.changeToQuantBytes;
      guiState.changeToQuantBytes = null;
    }

    // Begin monitoring code for frames per second
    stats.begin();


    let minPoseConfidence;
    let minPartConfidence;

    const pose = await guiState.net.estimatePoses(video, {
      flipHorizontal: flipPoseHorizontal,
      decodingMethod: 'single-person'
    });

    minPoseConfidence = +guiState.singlePoseDetection.minPoseConfidence;
    minPartConfidence = +guiState.singlePoseDetection.minPartConfidence;

    ctx.clearRect(0, 0, videoWidth, videoHeight);

    if (guiState.output.showVideo) {
      ctx.save();
      ctx.scale(-1, 1);
      ctx.translate(-videoWidth, 0);
      ctx.drawImage(video, 0, 0, videoWidth, videoHeight);
      ctx.restore();
    }

    // For each pose (i.e. person) detected in an image, loop through the poses
    // and draw the resulting skeleton and keypoints if over certain confidence
    // scores


    const { score, keypoints } = pose[0];
    
      if(guiState.tapeDeck.recording) {
        guiState.sequence = guiState.sequence.concat({ score, keypoints });

        guiState.frameCounter++;
        frameCountDisplayController.setValue(guiState.frameCounter);
      }

      // set the keypoints array with one firebase setter function!
      if(guiState.tapeDeck.recording == false && guiState.tapeDeck.playing) {

        if(guiState.frameCounter >= guiState.sequence.length) {
          guiState.frameCounter = 0;
        }

        if(guiState.sequence.length > 0) {
          let framePose = guiState.sequence[guiState.frameCounter];
          guiState.frameCounter++;
          frameCountDisplayController.setValue(guiState.frameCounter);

          if(framePose) {
            
            // send recorded frame to firebase //  !  //
            db.ref("users/" + guiState.userId + "/playback").set(framePose.keypoints);

            // play recorded frame //  !  //
            if (guiState.output.showPoints) {
              drawKeypoints(framePose.keypoints, minPartConfidence, ctx);
            }
            if (guiState.output.showSkeleton) {
              drawSkeleton(framePose.keypoints, minPartConfidence, ctx);
            }
            if (guiState.output.showBoundingBox) {
              drawBoundingBox(framePose.keypoints, ctx);
            }
          }
        }
      } else {
        db.ref("users/" + guiState.userId + "/playback").set(keypoints);
        // to firebase live // > //
        if (guiState.output.showPoints) {
          drawKeypoints(keypoints, minPartConfidence, ctx);
        }
        if (guiState.output.showSkeleton) {
          drawSkeleton(keypoints, minPartConfidence, ctx);
        }
        if (guiState.output.showBoundingBox) {
          drawBoundingBox(keypoints, ctx);
        }

      }
      

    // End monitoring code for frames per second
    stats.end();

    requestAnimationFrame(poseDetectionFrame);
  }

  poseDetectionFrame();
}

/**
 * Kicks off the demo by loading the posenet model, finding and loading
 * available camera devices, and setting off the detectPoseInRealTime function.
 */
export async function bindPage() {
  toggleLoadingUI(true);
  const net = await posenet.load({
    architecture: guiState.input.architecture,
    outputStride: guiState.input.outputStride,
    inputResolution: guiState.input.inputResolution,
    multiplier: guiState.input.multiplier,
    quantBytes: guiState.input.quantBytes
  });
  toggleLoadingUI(false);

  let video;

  try {
    video = await loadVideo();
  } catch (e) {
    let info = document.getElementById('info');
    info.textContent = 'this browser does not support video capture,' +
        'or this device does not have a camera';
    info.style.display = 'block';
    throw e;
  }

  setupGui([], net);
  setupFPS();
  detectPoseInRealTime(video, net);
}

navigator.getUserMedia = navigator.getUserMedia ||
    navigator.webkitGetUserMedia || navigator.mozGetUserMedia;
// kick off the demo
bindPage();
