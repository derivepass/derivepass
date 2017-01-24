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

    if (!this.online)
      return;

    configure();

    this.container = CloudKit.getDefaultContainer();
    this.db = this.container.privateCloudDatabase;

    this.lastState = null;
    this.unsubscribe = null;

    this.setupAuth();

    this.syncQueue = false;
    this.fetchQueue = false;
    this.saveQueue = false;
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

    // Start sync early to optimize fetch records from initial apps
    this.sync();

    this.lastState = this.store.getState();
    this.unsubscribe = this.store.subscribe(() => {
      this.onStateChange();
    });

    // Handle initial applications
    this.lastState.applications.list.forEach(app => this.onAppChange(app));
  }

  onSignOut() {
    this.container.whenUserSignsIn()
      .then(user => this.onSignIn(user))
      .catch((err) => { this._logError(err); });

    this.props.onFocusNeeded();

    this.unsubscribe();
    this.unsubscribe = null;
  }

  onStateChange() {
    const oldState = this.lastState;
    if (!oldState)
      return;

    const newState = this.store.getState();
    this.lastState = newState;

    const changed = newState.applications.list.reduce((changed, app) => {
      if (oldState.applications.list.includes(app))
        return changed;

      return changed.concat(app);
    }, []);

    changed.forEach((app) => {
      this.onAppChange(app);
    });
  }

  fetchRecord(uuid, callback) {
    // `.sync()` is running, let it help us!
    if (this.syncQueue) {
      const item = {
        retry: () => { this.fetchRecord(uuid, callback); },
        done: callback
      };

      if (this.syncQueue.has(uuid))
        this.syncQueue.get(uuid).push(item);
      else
        this.syncQueue.set(uuid, [ item ]);
      return;
    }

    let run = !this.fetchQueue;
    if (run)
      this.fetchQueue = new Map();

    if (this.fetchQueue.has(uuid))
      this.fetchQueue.get(uuid).push(callback);
    else
      this.fetchQueue.set(uuid, [ callback ]);

    if (!run)
      return;

    process.nextTick(() => {
      this.bulkFetchRecords();
    });
  }

  bulkFetchRecords() {
    const queue = this.fetchQueue;
    this.fetchQueue = false;

    this.db.fetchRecords(Array.from(queue.keys())).then((res) => {
      this._handleBulkResponse(res, queue);
    });
  }

  saveRecord(rec, callback) {
    let run = !this.saveQueue;
    if (run)
      this.saveQueue = new Map();

    if (this.saveQueue.has(rec))
      this.saveQueue.get(rec).push(callback);
    else
      this.saveQueue.set(rec, [ callback ]);

    if (!run)
      return;

    process.nextTick(() => {
      this.bulkSaveRecords();
    });
  }

  bulkSaveRecords() {
    const queue = this.saveQueue;
    this.saveQueue = false;

    const map = new Map();
    const recs = Array.from(queue.keys());

    // Copy callbacks into `uuid => [callback]` map
    recs.forEach((rec) => {
      map.set(rec.recordName, queue.get(rec));
    });

    this.db.saveRecords(recs).then((res) => {
      this._handleBulkResponse(res, map);
    });
  }

  _handleBulkResponse(res, queue) {
    if (res.hasErrors) {
      for (let i = 0; i < res.errors.length; i++) {
        const err = res.errors[i];

        queue.get(err.recordName).forEach(cb => cb(err.ckErrorCode));
      }
    }

    for (let i = 0; i < res.records.length; i++) {
      const rec = res.records[i];
      if (!queue.has(rec.recordName))
        console.error(queue);
      queue.get(rec.recordName).forEach(cb => cb(null, rec));
    }
  }

  onAppChange(app) {
    this.fetchRecord(app.uuid, (err, res) => {
      // Not found - create a new one
      if (err === 'NOT_FOUND') {
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
      } else if (err) {
        return this._logError(err);
      }

      if (res.modified) {
        // Cloud version is newer - broadcast
        if (res.modified.timestamp > app.changedAt)
          return this.dispatchRecord(res);

        // Same version - skip update
        if (res.modified.timestamp === app.changedAt)
          return;
      }

      res.fields.domain.value = app.domain;
      res.fields.login.value = app.login;
      res.fields.revision.value = app.revision;

      res.fields.master.value = app.master;
      res.fields.index.value = app.index;
      res.fields.removed.value = app.removed ? 1 : 0;

      this.saveRecord(res, (err) => {
        // Retry!
        if (err === 'CONFLICT') {
          this.onAppChange(app);
        } else if (err) {
          this._logError(err);
          return;
        }

        // Done!
      });
    });
  }

  sync() {
    this.syncQueue = new Map();

    // Invoke queued actions
    this.db.performQuery({
      recordType: 'EncryptedApplication'
    }).then((res) => {
      const queue = this.syncQueue;
      this.syncQueue = false;

      // TODO(indutny): handle me
      if (res.hasErrors) {
        // Retry queued fetches
        queue.forEach(value => value.forEach(item => item.retry()));
        this._logError(res.errors);
        return;
      }

      const store = this.store;
      for (let i = 0; i < res.records.length; i++) {
        const rec = res.records[i];
        if (queue.has(rec.recordName))
          queue.get(rec.recordName).forEach(item => item.done(null, rec));
        this.dispatchRecord(rec);
      }
    }).catch((err) => { this._logError(err); });
  }

  dispatchRecord(rec) {
    const fields = rec.fields;

    this.store.dispatch(actions.syncApplication({
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
