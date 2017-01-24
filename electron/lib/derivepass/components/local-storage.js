'use strict';

const React = require('react');

const derivepass = require('../../derivepass');
const actions = derivepass.redux.actions;

const e = React.createElement;

class LocalStorage extends React.Component {
  constructor(params) {
    super(params);

    this.store = params.store;
    this.backend = window.localStorage;

    this.lastState = null;

    // Handle initial applications
    const apps = this.store.getState().applications;
    apps.list.forEach(app => this.onAppChange(app));

    // Avoid any state changes during constructor
    process.nextTick(() => {
      // Synchronously load all applications
      this.load();

      // Start handling updates only after synchronous `load`
      this.lastState = this.store.getState();
      this.store.subscribe(() => {
        this.onStateChange();
      });
    });
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

  onAppChange(app) {
    this.backend.setItem(`app/${derivepass.env}/${app.uuid}`, JSON.stringify({
      domain: app.domain,
      login: app.login,
      revision: app.revision,

      master: app.master,
      index: app.index,
      removed: app.removed,
      changedAt: app.changedAt
    }));
  }

  load() {
    const store = this.store;
    const backend = this.backend;

    const len = backend.length;
    for (let i = 0; i < len; i++) {
      const key = backend.key(i);
      if (!/^app\//.test(key))
        continue;

      const match = key.match(/^app\/([^\/]+)\//);
      if (match[1] !== derivepass.env)
        continue;

      const json = JSON.parse(backend.getItem(key));
      const uuid = key.replace(/^app\/[^\/]+\//, '');

      store.dispatch(actions.syncApplication({
        uuid,

        domain: json.domain,
        login: json.login,
        revision: json.revision,

        master: json.master,
        index: json.index,
        removed: json.removed,
        changedAt: json.changedAt
      }));
    }
  }

  render() {
    return null;
  }
}
module.exports = LocalStorage;
