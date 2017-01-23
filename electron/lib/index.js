'use strict';

const Emoji = require('./derivepass/emoji');
const Local = require('./derivepass/local');
const Remote = require('./derivepass/remote');
const ApplicationList = require('./derivepass/applist');
const Cryptor = require('./derivepass/cryptor');

const emoji = new Emoji('master', 'emoji');
const appList = new ApplicationList('apps');

const local = new Local();
const remote = new Remote({ local: local });

// For syncing back to iCloud
local.setRemote(remote);

local.on('update', () => {
  console.log('updated');
});

emoji.on('emoji', (emoji, master) => {
  appList.setApplications(local.getApplications(emoji), master);
});
