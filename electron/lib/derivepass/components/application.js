'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

class Application extends React.Component {
  render() {
    const domain = e('p', { className: 'application-domain' },
                     this.props.app.domain);
    const login = e('p', { className: 'application-login' },
                     this.props.app.login);

    return e('article', {
      className: 'application',
      onClick: () => {
        this.props.onClick();
      }
    }, domain, login);
  }
}
module.exports = Application;
