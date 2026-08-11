// Workaround for Node 24.17 + firebase-tools login ("Premature close").
const http = require('http');
const https = require('https');
http.globalAgent.keepAlive = false;
https.globalAgent.keepAlive = false;
