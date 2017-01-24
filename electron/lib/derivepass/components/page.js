'use strict';

const DELAY_TIMEOUT = 250;

const redux = require('redux');
const React = require('react');
const ReactRedux = require('react-redux');

const derivepass = require('../../derivepass');
const MasterPassword = derivepass.containers.MasterPassword;
const Config = derivepass.components.Config;
const ApplicationList = derivepass.containers.ApplicationList;
const LocalStorage = derivepass.components.LocalStorage;
const RemoteStorage = derivepass.components.RemoteStorage;
const TabView = derivepass.containers.TabView;

const actions = derivepass.redux.actions;

const e = React.createElement;

class Page extends React.Component {
  constructor() {
    super();

    this.cryptor = new derivepass.Cryptor();

    this.delayTimer = null;

    this.store = redux.createStore(derivepass.redux.reducers);
  }

  masterView() {
    return {
      id: 'MASTER',
      title: 'Master',
      elem: e(MasterPassword, {
        cryptor: this.cryptor,
        hasAppsForEmoji: (emoji) => {
          return this.store.getState().applications.list.some((app) => {
            return app.master === emoji;
          });
        }
      })
    };
  }

  applicationListView() {
    return {
      id: 'APPLICATIONS',
      title: 'Applications',
      elem: e(ApplicationList, {
        cryptor: this.cryptor,
        applications: []
      })
    };
  }

  configView() {
    return {
      id: 'CONFIG',
      title: 'Config',
      elem: e(Config)
    };
  }

  render() {
    const views = [
      this.masterView(),
      this.applicationListView(),
      this.configView()
    ];

    const page = e(
      'section',
      { className: 'page' },
      e(LocalStorage, { store: this.store }),
      e(RemoteStorage, {
        store: this.store,
        onFocusNeeded: () => this.store.dispatch(actions.selectTab('CONFIG'))
      }),
      e(TabView, { views }));

    return e(ReactRedux.Provider, { store: this.store }, page);
  }
}
module.exports = Page;
