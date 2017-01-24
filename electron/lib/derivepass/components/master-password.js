'use strict';

const React = require('react');

const derivepass = require('../../derivepass');
const Emoji = derivepass.components.Emoji;

const e = React.createElement;

class MasterPassword extends React.Component {
  constructor() {
    super();
    this.state = { password: '' };
  }

  onChange(e) {
    const password = e.target.value;
    this.setState({ password: password });
    this.props.onChange(password);
  }

  render() {
    return e(
      'section',
      { className: 'master' },
      e(Emoji, {
        input: this.state.password
      }),
      e('input', {
        type: 'password',
        className: 'master-password',
        placeholder: 'Master Password',
        onKeyPress: e => this.onChange(e),
        onKeyUp: e => this.onChange(e)
      })
    );
  }
}
module.exports = MasterPassword;
