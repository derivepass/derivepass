'use strict';

const ReactRedux = require('react-redux');
const derivepass = require('../../derivepass');
const TabView = derivepass.components.TabView;
const actions = derivepass.redux.actions;

function mapStateToProps(state, ownProps) {
  return {
    active: state.tab.active,
    views: ownProps.views
  };
}

function mapDispatchToProps(dispatch) {
  return {
    onClick: id => dispatch(actions.selectTab(id))
  };
}

module.exports = ReactRedux.connect(mapStateToProps, mapDispatchToProps)(
  TabView
);
