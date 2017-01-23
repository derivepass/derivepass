'use strict';

const App = require('./app');

function Local() {
  this.list = [];
  this.storage = window.localStorage;

  this.remote = null;

  this.load();
}
module.exports = Local;

Local.prototype.load = function load() {
  const storage = this.storage;

  const len = storage.length;
  for (let i = 0; i < len; i++) {
    const key = storage.key(i);
    if (!/^app\//.test(key))
      continue;

    const json = JSON.parse(storage.getItem(key));
    this.list.push(new App(key.slice(4), json));
  }
};

Local.prototype.setRemote = function setRemote(remote) {
  this.remote = remote;
};

Local.prototype.save = function save(onlyLocal) {
  for (let i = 0; i < this.list.length; i++) {
    const app = this.list[i];
    if (!app.changed)
      continue;

    app.changed = false;
    this.storage.setItem(`app/${app.uuid}`, JSON.stringify(app));
    if (!onlyLocal)
      this.remote.updateApp(app);
  }
};

Local.prototype.mergeRemoteApp = function mergeRemoteApp(remote) {
  let found = null;
  for (let i = 0; i < this.list.length; i++) {
    const app = this.list[i];
    if (app.uuid !== remote.recordName)
      continue;

    found = app;
    break;
  }
  if (!found) {
    found = new App(remote.recordName, {});
    this.list.push(found);
  }

  const app = found;
  app.set('domain', remote.fields.domain.value);
  app.set('login', remote.fields.login.value);
  app.set('revision', remote.fields.revision.value);
  app.set('master', remote.fields.master.value);
  app.set('index', remote.fields.index.value);
  app.set('removed', remote.fields.removed.value ? true : false);
  app.set('changedAt', remote.modified.timestamp);
};

Local.prototype.getApplications = function getApplications(master) {
  const res = [];
  for (let i = 0; i < this.list.length; i++)
    if (this.list[i].get('master') === master && !this.list[i].get('removed'))
      res.push(this.list[i]);
  return res;
};
