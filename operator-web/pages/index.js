import Layout from '../components/MyLayout';
import Link from 'next/link';
import fetch from 'isomorphic-unfetch';

import firebase from 'firebase/app';
import db from '../firebaseApp';
import 'firebase/database'

import { useList, useObjectVal } from 'react-firebase-hooks/database';

const focusParts = ['rightKidney', 'leftKidney', 'hyoidBone', 'leftVestibular', 'jadePillow', 'rightFibula', 'aorta', 'heartAndLungs', 'perineum', 'tail', 'leftFloatingRibs', 'reqightDistalRadius'];

const handleRadio = (e) => {
  db.ref('ui/control/focusPart').set(e.target.value);
}

const stopRecording = () => {
  db.ref('ui/control/recording').set(false);
}
const startRecording = () => {
  db.ref('ui/control/recording').set(true);
}

const Index = props => {
  const [partVal, partLoading, partError] = useObjectVal(db.ref('ui/control/focusPart'));
  const [recordingVal, recordingLoading, recordingError] = useObjectVal(db.ref('ui/control/recording'));

  const toggleButton = recordingVal ? (<button onClick={stopRecording}>stop</button>) : (<button onClick={startRecording}>start</button>);
  const statusEmoji = recordingVal ? "🔴" : "⚪";

  return (
    <Layout>
      <h1>LCP Performance Operator</h1>
      <h3>focused part: {partVal}</h3>
      { focusParts.map(part => {
        return (
          <div key={part}>
            <input
              type="radio"
              id={part}
              name="focuspart"
              value={part}
              onChange={handleRadio}
              checked={partVal === part}
            />
            <label htmlFor={part}>{part}</label><br />
          </div>
        );
      })}

      <h3>recording: {statusEmoji}</h3>
      { toggleButton }
    </Layout>
  );

}

export default Index;
