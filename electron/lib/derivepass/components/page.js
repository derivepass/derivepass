'use strict';

const redux = require('redux');
const React = require('react');

const derivepass = require('../../derivepass');
const MasterPassword = derivepass.components.MasterPassword;
const Config = derivepass.components.Config;
const LocalStorage = derivepass.components.LocalStorage;
const RemoteStorage = derivepass.components.RemoteStorage;
const TabView = derivepass.components.TabView;

const e = React.createElement;

class Page extends React.Component {
  constructor() {
    super();

    this.state = {
      master: '',
      tabs: {
        active: 0
      }
    };

    // TODO(indutny): hydrate with values from localStorage
    this.store = redux.createStore(derivepass.redux.reducers);
  }

  render() {
    const views = [
      {
        id: 'master',
        title: 'Master',
        elem: e(MasterPassword, {
          onChange: (v) => {
            this.setState(Object.assign({}, this.state, {
              master: v
            }));
          }
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
        e(RemoteStorage, { store: this.store }),
        e(TabView, {
          views,
          active: this.state.tabs.active,
          onClick: (i) => {
            this.setState(Object.assign({}, this.state, {
              tabs: { active: i }
            }));
          }
        }));
  }
}
module.exports = Page;
