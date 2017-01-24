'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

class Application extends React.Component {
  render() {
    const props = this.props;

    const domain = e('p', { className: 'application-domain' },
                     props.app.domain);
    const login = e('p', { className: 'application-login' }, props.app.login);

    const edit = e('button', {
      className: 'application-edit',
      onClick: (e) => {
        e.stopPropagation();
        this.props.onEdit();
      }
    }, '✏️');

    return e('article', {
      className: `application application-${props.view.state.toLowerCase()}`,
      onClick: this.props.onClick
    }, domain, login, edit);
  }
}
module.exports = Application;
