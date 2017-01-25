'use strict';

process.env.NODE_ENV = 'production';

const React = require('react');
const ReactDOM = require('react-dom');

const derivepass = exports;

derivepass.env = process.env.NODE_ENV === 'production' ?
    'production' : 'development';

// CloudKit requires cookies... Emulate them!
require('./derivepass/utils/local-cookie').env = derivepass.env;

// Various
derivepass.Cryptor = require('./derivepass/cryptor');

// Redux definitions

const redux = {};
derivepass.redux = redux;
redux.actions = require('./derivepass/redux/actions');
redux.reducers = require('./derivepass/redux/reducers');

// React-Redux containers
const containers = {};
derivepass.containers = containers;

// React components

const components = {};
derivepass.components = components;

components.MasterPassword = require('./derivepass/components/master-password');
containers.MasterPassword = require('./derivepass/containers/master-password');

components.Config = require('./derivepass/components/config');
components.LocalStorage = require('./derivepass/components/local-storage');
components.RemoteStorage = require('./derivepass/components/remote-storage');

components.Application = require('./derivepass/components/application');
containers.Application = require('./derivepass/containers/application');

components.ApplicationList =
    require('./derivepass/components/application-list');
containers.ApplicationList =
    require('./derivepass/containers/application-list');

components.TabView = require('./derivepass/components/tab-view');
containers.TabView = require('./derivepass/containers/tab-view');

components.Page = require('./derivepass/components/page');

derivepass.start = (id) => {
  ReactDOM.render(React.createElement(components.Page),
                  document.getElementById(id));
};
