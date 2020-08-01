'use strict';

var firebase = require("firebase");
var osc = require('osc');

// Initialize firebase
var firebaseConfig = {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    databaseURL: process.env.FIREBASE_DATABASE_URL,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.FIREBASE_APP_ID
  };

  firebase.initializeApp(firebaseConfig);
  var db = firebase.database();
  var rootRef = db.ref();

// config and open udp port
var udpPort = new osc.UDPPort({
    localAddress: "0.0.0.0",
    localPort: 99999,
    remoteAddress: "0.0.0.0",
    remotePort: 10419,
    metadata: true
});
udpPort.open();

rootRef.on("value", function(snapshot) {
  var keypoints = snapshot.val();

  for (var part in keypoints) {
    // send part data as OSC over udp
    var userData = keypoints[part];
    udpPort.send({
      address: `/lcp/tracking/${part}`,
      args: [
        {
          type: "f",
          value: userData.position.x
        },
        {
          type: "f",
          value: userData.position.y
        },
        {
          type: "f",
          value: userData.score
        }
      ]
    });
  }
});

console.log("\nwelcome to lcp-firebase-osc-relay!\n")

console.log("relaying pose data from firebase to localhost:10419 ...")
