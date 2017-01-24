'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

class MasterPassword extends React.Component {
  render() {
    const props = this.props;

    return e(
      'section',
      { className: 'master' },
      e('p', {
        className: 'emoji'
      }, props.emoji),
      e('input', {
        type: 'password',
        className: 'master-password',
        placeholder: 'Master Password',
        value: props.master,
        onChange: (e) => props.onChange(e.target.value, props.computing)
      })
    );
  }
}
module.exports = MasterPassword;
