'use strict';

const Emoji = require('./derivepass/emoji');
const Local = require('./derivepass/local');
const Remote = require('./derivepass/remote');
const ApplicationList = require('./derivepass/applist');
const Cryptor = require('./derivepass/cryptor');

const env = process.env.NODE_ENV === 'development' ?
    'development' : 'production';

const emoji = new Emoji('master', 'emoji');
const appList = new ApplicationList('apps');

const cryptor = new Cryptor();
const local = new Local(cryptor, { env: env });
const remote = new Remote({ local: local, env: env });

// For syncing back to iCloud
local.setRemote(remote);

local.on('update', () => {
  console.log('updated');
});

let timeout;

emoji.on('emoji', (emoji, master) => {
  function onKeys(err) {
    if (err)
      throw err;

    appList.setApplications(local.getApplications(emoji), master);
  }

  cryptor.reset();
  clearTimeout(timeout);
  timeout = setTimeout(() => {
    cryptor.deriveKeys(master, onKeys);
  }, 250);
});
