'use strict';

var firebase = require("firebase");
var osc = require('osc');

// Initialize firebase
//
var FIREBASE_DATABASE_URL="https://lcp-human-robot-performance.firebaseio.com";
var FIREBASE_AUTH_DOMAIN="lcp-human-robot-performance.firebaseapp.com";
var FIREBASE_API_KEY="AIzaSyDivUHq7yQ0NFhKJWU5uO4x_VK6LYHsiJo";
var FIREBASE_PROJECT_ID="lcp-human-robot-performance";
var FIREBASE_STORAGE_BUCKET="lcp-human-robot-performance.appspot.com";
var FIREBASE_MESSAGING_SENDER_ID="824569421218";
var FIREBASE_APP_ID="1:824569421218:web:bee37ca081137d3bf566fb";

var firebaseConfig = {
    apiKey: FIREBASE_API_KEY,
    authDomain: FIREBASE_AUTH_DOMAIN,
    databaseURL: FIREBASE_DATABASE_URL,
    projectId: FIREBASE_PROJECT_ID,
    storageBucket: FIREBASE_STORAGE_BUCKET,
    messagingSenderId: FIREBASE_MESSAGING_SENDER_ID,
    appId: FIREBASE_APP_ID
  };

let usersList = [
"clareanneyagustin",
"jaliana",
"gaustin",
"leahzbasnight",
"meganbaytosh",
"amity",
"nataliebianchi",
"cmcargnoni",
"elisacastillo",
"jchin",
"mcolehower",
"bdodgion",
"emilyeckert",
"sydneygottlieb",
"miagriff",
"j_a_hayes",
"eisroelit",
"madelinejosa",
"cheuk-kwan",
"ninalopez",
"emmarose",
"cmccarthy",
"kyliemccreary",
"isabelmeena",
"dalyamodlin",
"linapersson",
"katrinareinart",
"sshahgholian",
"devynshanley",
"tabithastewart",
"s_yuen",
"kearazengel",
"lzorba",
"mark",
"sam",
"brooke",
"philip"
];

let userId = process.argv.length > 2 ? process.argv[2] : 'default';
firebase.initializeApp(firebaseConfig);
var db = firebase.database();
//var playbackRef = db.ref(`users/${userId}/playback`);
var audioTriggerRef = db.ref("audio/trigger");
var focusPartRef = db.ref("ui/control/focusPart");
var recordingRef = db.ref("ui/control/recording");

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

focusPartRef.on("value", function(snapshot) {
  var focusPart = snapshot.val();
  if(!focusPart) {
    console.error("error on body parts-- focusPart is falsey");
    return;
  };

  udpPort.send({
      address: "/lcp/control/focusPart",
      args: [
        {
          type: "s",
          value: focusPart
        }
      ]
    });
})

recordingRef.on("value", function(snapshot) {
  var isRecording = snapshot.val(); // JS boolean

  udpPort.send({
      address: "/lcp/control/recording",
      args: [
        {
          type: "i",
          value: isRecording ? 1 : 0 // transformed to 0/1 ints
        }
      ]
    });
})

var snapshotHandler = function(index, handle, snapshot) { // creates a listener -- or a binding to firebase server
  var keypoints = snapshot.val();
  if(!keypoints) {
    console.error(`Error: there is no user ${handle} on firebase`);
    console.error("Perhaps you need to open the posenet tracker to initialize the user");
    return false;
  };

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

  //console.log(`received data from ___, sending as id ${index}`);
  udpPort.send({
    address: `/lcp/tracking/multi/${index}`,
    args: partsArray
  });
};

var arrayOfRefs = usersList.map(function(user) {
  return db.ref(`users/${user}/playback`)
});

for(var i=0; i<usersList.length; i++) {
  var addr = `users/${usersList[i]}/playback`;
  arrayOfRefs[i].on("value", snapshotHandler.bind(null, i, usersList[i]));
}

console.log("\nwelcome to firebase_osc_relay!\n")

console.log("relaying pose data from firebase to localhost:10419 ...")
