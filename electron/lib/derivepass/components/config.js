'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

class Config extends React.Component {
  onChange(e) {
    const password = e.target.value;
    this.setState({ password: password });
    this.props.onChange(password);
  }

  render() {
    return e(
      'section',
      { className: 'config' },
      e('span', {}, 'iCloud status:'),
      e('section', { id: 'apple-sign-in-button' }),
      e('section', { id: 'apple-sign-out-button' }));
  }
}
module.exports = Config;
