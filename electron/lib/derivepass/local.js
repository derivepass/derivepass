'use strict';

const util = require('util');
const EventEmitter = require('events').EventEmitter;
const App = require('./app');

function Local() {
  EventEmitter.call(this);

  this.list = [];
  this.storage = window.localStorage;

  this.remote = null;

  this.load();
}
util.inherits(Local, EventEmitter);
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
  let changed = false;

  for (let i = 0; i < this.list.length; i++) {
    const app = this.list[i];
    if (!app.changed)
      continue;
    changed = true;

    app.changed = false;
    this.storage.setItem(`app/${app.uuid}`, JSON.stringify(app));
    if (!onlyLocal)
      this.remote.updateApp(app);
  }

  // New or updated apps!
  if (changed)
    this.emit('update');
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
  app.setRaw('domain', remote.fields.domain.value);
  app.setRaw('login', remote.fields.login.value);
  app.setRaw('revision', remote.fields.revision.value);
  app.setRaw('master', remote.fields.master.value);
  app.setRaw('index', remote.fields.index.value);
  app.setRaw('removed', remote.fields.removed.value ? true : false);
  app.setRaw('changedAt', remote.modified.timestamp);
};

Local.prototype.getApplications = function getApplications(master) {
  const res = [];
  for (let i = 0; i < this.list.length; i++)
    if (this.list[i].get('master') === master && !this.list[i].get('removed'))
      res.push(this.list[i]);
  return res.sort((a, b) => a.index - b.index);
};
