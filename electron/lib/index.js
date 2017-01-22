'use strict';

const Local = require('./derivepass/local');
const Remote = require('./derivepass/remote');

const local = new Local();
const remote = new Remote({ local: local });
