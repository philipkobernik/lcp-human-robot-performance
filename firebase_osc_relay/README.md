# firebase-osc-relay

This node script connects to a firebase realtime database and relays changes over OSC.

This script expects firebase db data to look like so:

````
"user1": 0.23,
"user2": 0.42
````

When the float value of the "user1" key changes, this node app will send out an updated value over UDP to the OSC address "/user1"

OSC messages are currently sent to UDP port 5557.

The script connects to a firebase db using credentials/urls specified in a local .env file. Check out `example.env` for what this file should contain. Fill it out, rename it to `.env` and you should be good to go.

## Future work
* parameters for UDP port
* support interfaces that have more than one UI control
* send multiple values in one OSC message (reduce unnecessary message volume)
* remove hardcoded list of users -- extract user from firebase data
