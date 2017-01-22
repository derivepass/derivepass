'use strict';

const electron = require('electron');
const CloudKit = require('./cloudkit');

const API_TOKEN =
    '30bf89337751af96bf704397f1936a412551ec9f24b91819c07400cd7f6c4324';

CloudKit.configure({
  containers: [{
    containerIdentifier: 'iCloud.com.indutny.DerivePass',
    apiTokenAuth: {
      apiToken: API_TOKEN,
      persist: true
    },
    environment: process.env.NODE_ENV === 'development' ? 'development' :
        'production'
  }]
});

// Totally a hack to handle Apple ID authentication
// CloudKit can't live without cookies
require('./utils/local-cookie.js');

// CloudKit opens new window for auth
window.open = (href) => {
  electron.ipcRenderer.send('do-auth', href);
  electron.ipcRenderer.once('auth', (event, data) => {
    var event = new Event('message');
    event.data = data;
    window.dispatchEvent(event);
  });
};
// End of the hack


// TODO(indutny): handle promise rejections?
function Remote(options) {
  this.local = options.local;
  this.container = CloudKit.getDefaultContainer();
  this.db = this.container.privateCloudDatabase;

  this.online = false;

  this.initAuth();
}
module.exports = Remote;

Remote.prototype.initAuth = function initAuth() {
  this.container.setUpAuth().then((user) => {
    if (user)
      this.onSignIn(user);
    else
      this.onSignOut();
  }).catch((err) => {});
};

Remote.prototype.onSignIn = function onSignIn(user) {
  this.container.whenUserSignsOut()
    .then(user => this.onSignOut())
    .catch((err) => {});

  this.online = true;
  this.sync();
};

Remote.prototype.onSignOut = function onSignOut() {
  this.container.whenUserSignsIn()
    .then(user => this.onSignIn(user))
    .catch((err) => {});

  this.online = false;
};

Remote.prototype.sync = function sync() {
  // Invoke queued actions
  this.db.performQuery({
    recordType: 'EncryptedApplication'
  }).then((res) => {
    // TODO(indutny): handle me
    if (res.hasErrors) {
      console.error(res.errors);
      return;
    }

    console.log(res.records);
    for (let i = 0; i < res.records.length; i++)
      this.local.mergeRemoteApp(res.records[i]);
  }).catch((err) => {});
};

Remote.prototype.updateApp = function updateApp(app) {
  this.db.fetchRecords(app.uuid).then((res) => {
    // TODO(indutny): retry
    if (res.hasErrors) {
      console.error(res.errors);
      return;
    }

    // TODO(indutny): check that modification date is less than of the app

    res.fields.domain.value = app.domain;
    res.fields.login.value = app.login;
    res.fields.revision.value = app.revision;

    res.fields.master.value = app.master;
    res.fields.index.value = app.index;
    res.fields.removed.value = app.removed ? 1 : 0;

    this.db.saveRecords(res).then((res) => {
      if (res.hasErrors) {
        console.error(res.errors);
        return;
      }

      // Done!
    }).catch((err) => {});
  }).catch((err) => {});
};
