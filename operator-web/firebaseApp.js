import firebase from 'firebase/app';
import 'firebase/database';

var firebaseConfig = {
    apiKey: "AIzaSyDivUHq7yQ0NFhKJWU5uO4x_VK6LYHsiJo",
    authDomain: "lcp-human-robot-performance.firebaseapp.com",
    databaseURL: "https://lcp-human-robot-performance.firebaseio.com",
    projectId: "lcp-human-robot-performance",
    storageBucket: "lcp-human-robot-performance.appspot.com",
    messagingSenderId: "824569421218",
    appId: "1:824569421218:web:bee37ca081137d3bf566fb"
    };
// Initialize Firebase
var db;
if(firebase.apps.length < 1) {
  db = firebase.initializeApp(firebaseConfig).database();
} else {
  db = firebase.database();
}

export default db;
