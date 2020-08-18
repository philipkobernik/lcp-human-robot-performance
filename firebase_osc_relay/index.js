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
  var rootRef = db.ref("default"); // TODO: add args on startup to examine a certain user's stream

// config and open udp port
var udpPort = new osc.UDPPort({
    localAddress: "0.0.0.0",
    localPort: 99999,
    remoteAddress: "0.0.0.0",
    remotePort: 10419,
    metadata: true
});
udpPort.open();

var wekinatorPort = new osc.UDPPort({
  localAddress: "0.0.0.0",
  localPort: 99998,
  remoteAddress: "0.0.0.0",
  remotePort: 6448,
  metadata: true
});
wekinatorPort.open();



rootRef.on("value", function(snapshot) {
  var keypoints = snapshot.val();
  
  var partsArray = keypoints.map(part => {
    return [
      {
        type: "s",
        value: part.part
      },
      {
        type: "f",
        value: part.score
      },
      {
        type: "f",
        value: part.position.x
      },
      {
        type: "f",
        value: part.position.y
      }
    ];
  })

  var wekInputs = [];

  // let nosePos = keypoints[0].position;
  // let rWrist = keypoints[10].position;
  
  // let distance = Math.sqrt(Math.pow(nosePos.x - rWrist.x, 2) + Math.pow(nosePos.y - rWrist.y,2));

  // wekInputs = wekInputs.concat(
  //   {
  //     type: "f",
  //     value: distance
  //   }
  // );

  // [0,1,2,3,4,5,6].forEach(index => {
  //   wekInputs = wekInputs.concat(
  //     {
  //       type: "f",
  //       value: keypoints[index].position.x
  //     }
  //   );
  //   wekInputs = wekInputs.concat(
  //     {
  //       type: "f",
  //       value: keypoints[index].position.y
  //     }
  //   );
  // }); // list of 14 floats

  // if(distance !== NaN) {
  //   wekinatorPort.send({
  //     address: "/wek/inputs",
  //     args: wekInputs
  //   })
  // }

  udpPort.send({
    address: `/lcp/tracking/pose`,
    args: partsArray
  });

});

console.log("\nwelcome to firebase_osc_relay!\n")

console.log("relaying pose data from firebase to localhost:10419 ...")
