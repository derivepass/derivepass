'use strict';

const Emoji = require('./derivepass/emoji');
const Local = require('./derivepass/local');
const Remote = require('./derivepass/remote');
const ApplicationList = require('./derivepass/applist');
const Cryptor = require('./derivepass/cryptor');

const env = process.env.NODE_ENV === 'development' ?
    'development' : 'production';

const emoji = new Emoji('master', 'emoji');

const cryptor = new Cryptor();
const local = new Local(cryptor, { env: env });
const remote = new Remote({ local: local, env: env });

// For syncing back to iCloud
local.setRemote(remote);

const appList = new ApplicationList('apps', {
  local: local,
  remote: remote,
  cryptor: cryptor
});

emoji.on('emoji', (emoji, master) => {
  this.setMaster(emoji, master);
});
