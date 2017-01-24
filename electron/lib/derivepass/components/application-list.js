'use strict';

const React = require('react');

const derivepass = require('../../derivepass');
const Application = derivepass.components.Application;

const e = React.createElement;

class ApplicationList extends React.Component {
  render() {
    return e('section', {
      className: 'application-list'
    }, this.props.applications.map((app) => {
      return e(Application, { key: app.uuid, app: app });
    }));
  }
}
module.exports = ApplicationList;
