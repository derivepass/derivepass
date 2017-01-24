'use strict';

const DELAY_TIMEOUT = 250;

const redux = require('redux');
const React = require('react');

const derivepass = require('../../derivepass');
const MasterPassword = derivepass.components.MasterPassword;
const Config = derivepass.components.Config;
const ApplicationList = derivepass.components.ApplicationList;
const LocalStorage = derivepass.components.LocalStorage;
const RemoteStorage = derivepass.components.RemoteStorage;
const TabView = derivepass.components.TabView;

const e = React.createElement;

class Page extends React.Component {
  constructor() {
    super();

    this.state = {
      master: '',
      applications: [],
      activeTab: 'master'
    };

    this.delayTimer = null;

    // TODO(indutny): hydrate with values from localStorage
    this.store = redux.createStore(derivepass.redux.reducers);

    this.store.subscribe(() => {
      const state = this.store.getState();
      this.setState(Object.assign({}, this.state, {
        applications: state.applications
      }));
    });
  }

  onMasterChange(value) {
    clearTimeout(this.delayTimer);
    this.delayTimer = setTimeout(() => {
      this.setState(Object.assign({}, this.state, {
        master: value
      }));
    }, DELAY_TIMEOUT);
  }

  render() {
    const views = [
      {
        id: 'master',
        title: 'Master',
        elem: e(MasterPassword, {
          onChange: (v) => this.onMasterChange(v)
        })
      },
      {
        id: 'applications',
        title: 'Applications',
        elem: e(ApplicationList, {
          applications: this.state.applications
        })
      },
      {
        id: 'config',
        title: 'Config',
        elem: e(Config)
      }
    ];

    return e(
        'section', { className: 'page' },
        e(LocalStorage, { store: this.store }),
        e(RemoteStorage, {
          store: this.store,
          onFocusNeeded: () => {
            this.setState(Object.assign({}, this.state, {
              activeTab: 'config'
            }));
          }
        }),
        e(TabView, {
          views,
          active: this.state.activeTab,
          onClick: (i) => {
            this.setState(Object.assign({}, this.state, {
              activeTab: i
            }));
          }
        }));
  }
}
module.exports = Page;
