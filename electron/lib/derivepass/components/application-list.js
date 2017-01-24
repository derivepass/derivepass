'use strict';

const React = require('react');

const derivepass = require('../../derivepass');
const Application = derivepass.containers.Application;

const e = React.createElement;

class ApplicationList extends React.Component {
  render() {
    let noApps;

    if (!this.props.allowCreate && this.props.applications.length === 0) {
      if (this.props.master.password.length !== 0) {
        noApps = e('article', {
          className: 'application-list-computing'
        }, e('p', {}, 'Please wait...'));
      } else {
        noApps = e('article', {
          className: 'application-list-no-apps'
        }, e('p', {}, 'No applications yet...'),
           e('p', {}, 'Please enter master password first'));
      }
    }

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
    }), noApps);
  }
}
module.exports = ApplicationList;
