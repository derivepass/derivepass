'use strict';

const electron = require('electron');
const React = require('react');

const derivepass = require('../../derivepass');
const actions = derivepass.redux.actions;

const e = React.createElement;

// Totally a hack to handle Apple ID authentication

// CloudKit opens new window for auth
if (typeof window !== 'undefined') {
  window.open = (href) => {
    electron.ipcRenderer.send('do-auth', href);
    electron.ipcRenderer.once('auth', (event, data) => {
      var event = new Event('message');
      event.data = data;
      window.dispatchEvent(event);
    });
  };
}
// End of the hack

const API_TOKEN = derivepass.env === 'development' ?
    '30bf89337751af96bf704397f1936a41' +
        '2551ec9f24b91819c07400cd7f6c4324' :
    '3f90a4ad293a3e4b7005dfe5c4b3872e' +
        'b9d5cc91041843a297750d047888f824';

let configured = false;
function configure() {
  if (configured)
    return;
  configured = true;

  CloudKit.configure({
    containers: [{
      containerIdentifier: 'iCloud.com.indutny.DerivePass',
      apiTokenAuth: {
        apiToken: API_TOKEN,
        persist: true
      },
      environment: derivepass.env
    }]
  });
}

class RemoteStorage extends React.Component {
  constructor(params) {
    super(params);

    this.store = params.store;
    this.online = typeof CloudKit !== 'undefined';
    if (!this.online) {
      this.container = null;
      this.db = null;
      this.lastState = null;
      this.unsubscribe = null;
      return;
    }

    configure();

    this.container = CloudKit.getDefaultContainer();
    this.db = this.container.privateCloudDatabase;

    this.lastState = null;
    this.unsubscribe = null;

    this.setupAuth();
  }

  _logError(err) {
    // TODO(indutny): handle these errors
    console.error(err);
  }

  setupAuth() {
    this.container.setUpAuth().then((user) => {
      if (user)
        this.onSignIn(user);
      else
        this.onSignOut();
    }).catch((err) => { this._logError(err); });
  }

  onSignIn(user) {
    this.container.whenUserSignsOut()
      .then(user => this.onSignOut())
      .catch((err) => { this._logError(err); });

    this.lastState = this.store.getState();
    this.unsubscribe = this.store.subscribe(() => {
      this.onStateChange();
    });

    // Handle initial applications
    this.lastState.applications.forEach(app => this.onAppChange(app));

    this.sync();
  }

  onSignOut() {
    this.container.whenUserSignsIn()
      .then(user => this.onSignIn(user))
      .catch((err) => { this._logError(err); });

    this.unsubscribe();
    this.unsubscribe = null;
  }

  onStateChange() {
    const oldState = this.lastState;
    if (!oldState)
      return;

    const newState = this.store.getState();
    this.lastState = newState;

    const changed = newState.applications.reduce((changed, app) => {
      if (oldState.applications.includes(app))
        return changed;

      return changed.concat(app);
    }, []);

    changed.forEach((app) => {
      this.onAppChange(app);
    });
  }

  onAppChange(app) {
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
      } else {
        res = res.records[0];
      }

      if (res.modified) {
        // Cloud version is newer - broadcast
        if (res.modified.timestamp > app.modifiedAt)
          return this.dispatchRecord(res);

        // Same version - skip update
        if (res.modified.timestamp === app.modifiedAt)
          return;
      }

      res.fields.domain.value = app.domain;
      res.fields.login.value = app.login;
      res.fields.revision.value = app.revision;

      res.fields.master.value = app.master;
      res.fields.index.value = app.index;
      res.fields.removed.value = app.removed ? 1 : 0;

      this.db.saveRecords(res).then((res) => {
        if (res.hasErrors) {
          if (res.errors[0].ckErrorCode !== 'CONFLICT') {
            this._logError(res.errors);
            return;
          }

          // Conflict - retry
          this.onAppChange(app);
          return;
        }

        // Done!
      }).catch((err) => { this._logError(err); });
    }).catch((err) => { this._logError(err); });
  }

  sync() {
    // Invoke queued actions
    this.db.performQuery({
      recordType: 'EncryptedApplication'
    }).then((res) => {
      // TODO(indutny): handle me
      if (res.hasErrors) {
        this._logError(res.errors);
        return;
      }

      const store = this.store;
      for (let i = 0; i < res.records.length; i++)
        this.dispatchRecord(res.records[i]);
    }).catch((err) => { this._logError(err); });
  }

  dispatchRecord(rec) {
    const fields = rec.fields;

    store.dispatch(actions.syncApplication({
      uuid: rec.recordName,

      domain: fields.domain.value,
      login: fields.login.value,
      revision: fields.revision.value,

      master: fields.master.value,
      index: fields.index.value,
      removed: fields.removed.value ? true : false,
      changedAt: rec.modified.timestamp
    }));
  }

  render() {
    return null;
  }
}
module.exports = RemoteStorage;
