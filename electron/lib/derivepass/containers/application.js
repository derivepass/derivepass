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
    app: raw === null ? null : {
      domain: cryptor.decrypt(raw.domain),
      login: cryptor.decrypt(raw.login),
      revision: cryptor.decryptNumber(raw.revision),
      index: raw.index
    }
  };
}

function mapDispatchToProps(dispatch, ownProps) {
  const cryptor = ownProps.cryptor;
  const raw = ownProps.app;

  return {
    copyPassword: (master, app, done) => {
      cryptor.derivePassword(master.password, app, (err, password) => {
        if (err)
          console.error(err);
        else
          electron.clipboard.writeText(password);

        done(null);
      });
    },
    onSave: (app) => {
      const encrypted = {
        domain: cryptor.encrypt(app.domain),
        login: cryptor.encrypt(app.login),
        revision: cryptor.encryptNumber(app.revision),

        changedAt: Date.now()
      };

      dispatch(actions.updateApplication(raw.uuid, encrypted));
    },
    onRemove: () => {
      dispatch(actions.removeApplication(raw.uuid, Date.now()));
    }
  };
}

module.exports = ReactRedux.connect(mapStateToProps, mapDispatchToProps)(
  Application
);
