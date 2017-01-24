'use strict';

const ReactRedux = require('react-redux');
const derivepass = require('../../derivepass');
const ApplicationList = derivepass.components.ApplicationList;

function mapStateToProps(state, ownProps) {
  if (state.master.computing !== 'READY')
    return { applications: [] };

  return {
    master: state.master,
    cryptor: ownProps.cryptor,
    applications: state.applications.list.filter((app) => {
      return !app.removed && app.master === state.master.emoji;
    }).sort((a, b) => {
      return a.index - b.index;
    })
  };
}

module.exports = ReactRedux.connect(mapStateToProps)(
  ApplicationList
);
