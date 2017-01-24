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
    }), this.props.allowCreate && e(Application, {
      cryptor: this.props.cryptor,
      app: null,
      onCreate: (info) => {
        this.props.onCreate(this.props.master, Object.assign({}, info, {
          index: this.props.applications.length
        }));
      }
    }));
  }
}
module.exports = ApplicationList;
