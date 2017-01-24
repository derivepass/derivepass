'use strict';

const electron = require('electron');
const ReactRedux = require('react-redux');
const derivepass = require('../../derivepass');
const Application = derivepass.components.Application;
const actions = derivepass.redux.actions;

function mapStateToProps(state, ownProps) {
  const cryptor = ownProps.cryptor;

  const raw = ownProps.app;
  return {
    raw,
    master: state.master,
    view: raw.view,
    app: {
      domain: cryptor.decrypt(raw.domain),
      login: cryptor.decrypt(raw.login),
      revision: cryptor.decryptNumber(raw.revision)
    }
  };
}

function mapDispatchToProps(dispatch, ownProps) {
  const cryptor = ownProps.cryptor;
  const raw = ownProps.app;

  return {
    onClick: (master, app) => {
      if (raw.view.state !== 'NORMAL')
        return;

      dispatch(actions.toggleApplicationView(raw.uuid, 'COMPUTING'));
      cryptor.derivePassword(master.password, app, (err, password) => {
        dispatch(actions.toggleApplicationView(raw.uuid, 'NORMAL'));
        if (err)
          return console.error(err);

        electron.clipboard.writeText(password);
      });
    },
    onEdit: () => {
      if (raw.view.state !== 'NORMAL')
        return;
      dispatch(actions.toggleApplicationView(raw.uuid, 'EDIT'));
    },
    onSave: (app) => {
      if (raw.view.state !== 'EDIT')
        return;
      dispatch(actions.toggleApplicationView(raw.uuid, 'NORMAL'));
    }
  };
}

module.exports = ReactRedux.connect(mapStateToProps, mapDispatchToProps)(
  Application
);
