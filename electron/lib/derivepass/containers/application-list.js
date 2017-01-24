'use strict';

const ReactRedux = require('react-redux');
const uuidV4 = require('uuid/v4');
const derivepass = require('../../derivepass');
const ApplicationList = derivepass.components.ApplicationList;
const actions = derivepass.redux.actions;

function mapStateToProps(state, ownProps) {
  if (state.master.computing.status !== 'READY' ||
      state.master.emoji !== state.master.computing.emoji ||
      state.master.password.length === 0) {
    return { master: state.master, applications: [] };
  }

  const apps = state.applications.list.filter((app) => {
    return !app.removed && app.master === state.master.emoji;
  }).sort((a, b) => {
    return a.index - b.index;
  });

  return {
    master: state.master,
    cryptor: ownProps.cryptor,
    allowCreate: true,
    applications: apps
  };
}

function mapDispatchToProps(dispatch, ownProps) {
  const cryptor = ownProps.cryptor;

  return {
    onCreate: (master, info) => {
      dispatch(actions.syncApplication({
        uuid: uuidV4(),

        domain: cryptor.encrypt(info.domain),
        login: cryptor.encrypt(info.login),
        revision: cryptor.encryptNumber(info.revision),

        index: info.index,
        removed: false,
        master: master.emoji,
        changedAt: Date.now()
      }))
    }
  };
}

module.exports = ReactRedux.connect(mapStateToProps, mapDispatchToProps)(
  ApplicationList
);
