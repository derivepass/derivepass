'use strict';

const electron = require('electron');
const CloudKit = require('./cloudkit');

const API_TOKEN = {
  development: '30bf89337751af96bf704397f1936a41' +
               '2551ec9f24b91819c07400cd7f6c4324',
  production: '3f90a4ad293a3e4b7005dfe5c4b3872e' +
              'b9d5cc91041843a297750d047888f824'
};

let configured = false;

// Totally a hack to handle Apple ID authentication

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
  if (!configured) {
    configured = true;
    CloudKit.configure({
      containers: [{
        containerIdentifier: 'iCloud.com.indutny.DerivePass',
        apiTokenAuth: {
          apiToken: API_TOKEN[options.env],
          persist: true
        },
        environment: options.env
      }]
    });

    // CloudKit can't live without cookies
    require('./utils/local-cookie.js').env = options.env;
  }

  this.local = options.local;
  this.container = CloudKit.getDefaultContainer();
  this.db = this.container.privateCloudDatabase;

  this.online = false;

  this.initAuth();
}
module.exports = Remote;

Remote.prototype._logError = function _logError(err) {
  console.error(err);
};

Remote.prototype.initAuth = function initAuth() {
  this.container.setUpAuth().then((user) => {
    if (user)
      this.onSignIn(user);
    else
      this.onSignOut();
  }).catch((err) => { this._logError(err); });
};

Remote.prototype.onSignIn = function onSignIn(user) {
  this.container.whenUserSignsOut()
    .then(user => this.onSignOut())
    .catch((err) => { this._logError(err); });

  this.online = true;
  this.sync();
};

Remote.prototype.onSignOut = function onSignOut() {
  this.container.whenUserSignsIn()
    .then(user => this.onSignIn(user))
    .catch((err) => { this._logError(err); });

  this.online = false;
};

Remote.prototype.sync = function sync() {
  // Invoke queued actions
  this.db.performQuery({
    recordType: 'EncryptedApplication'
  }).then((res) => {
    // TODO(indutny): handle me
    if (res.hasErrors) {
      this._logError(res.errors);
      return;
    }

    for (let i = 0; i < res.records.length; i++)
      this.local.mergeRemoteApp(res.records[i]);
    this.local.save(true);
  }).catch((err) => { this._logError(err); });
};

Remote.prototype.updateApp = function updateApp(app) {
  this.db.fetchRecords(app.uuid).then((res) => {
    if (res.hasErrors) {
      // Unexpected error!
      if (res.errors[0].ckErrorCode !== 'NOT_FOUND') {
        this._logError(res.errors);
        return;
      }

      // Not found - create a new one
      res = {
        recordType: 'EncryptedApplication',
        recordName: app.uuid,
        fields: {
          domain: {},
          login: {},
          revision: {},
          master: {},
          index: {},
          removed: {}
        }
      };
    }

    // Skip if items are the same
    if (res.modified && res.modified.timestamp == app.modifiedAt)
      return;

    res.fields.domain.value = app.getRaw('domain');
    res.fields.login.value = app.getRaw('login');
    res.fields.revision.value = app.getRaw('revision');

    res.fields.master.value = app.getRaw('master');
    res.fields.index.value = app.getRaw('index');
    res.fields.removed.value = app.getRaw('removed') ? 1 : 0;

    this.db.saveRecords(res).then((res) => {
      if (res.hasErrors) {
        if (res.errors[0].ckErrorCode !== 'CONFLICT') {
          this._logError(res.errors);
          return;
        }

        // Conflict - retry
        this.updateApp(app);
        return;
      }

      // Done!
    }).catch((err) => { this._logError(err); });
  }).catch((err) => { this._logError(err); });
};
