'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

class Application extends React.Component {
  render() {
    return e('div', { className: 'application' }, this.props.app.uuid);
  }
}
module.exports = Application;
