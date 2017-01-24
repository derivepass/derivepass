'use strict';

const React = require('react');

const derivepass = require('../../derivepass');
const Application = derivepass.containers.Application;

const e = React.createElement;

class ApplicationList extends React.Component {
  render() {
    return e('section', {
      className: 'application-list'
    }, this.props.applications.map((raw) => {
      return e(Application, {
        key: raw.uuid,

        cryptor: this.props.cryptor,
        app: raw
      });
    }));
  }
}
module.exports = ApplicationList;
