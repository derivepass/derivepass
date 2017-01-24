'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

const SHAKE_DELAY = 500;

class MasterPassword extends React.Component {
  constructor() {
    super();

    this.state = {
      confirming: false,
      original: null
    };
  }

  validateConfirmation() {
    const state = this.state;

    if (state.original.master === state.confirming.master)
      return true;

    this.setState(Object.assign({}, state, {
      shake: true
    }));
    setTimeout(() => {
      this.setState(Object.assign({}, this.state, {
        shake: false
      }));
    }, SHAKE_DELAY);

    return false;
  }

  render() {
    const props = this.props;
    const state = this.state;

    return e(
      'section',
      { className: 'master ' + (state.confirming ? 'master-confirm' : '') },
      e('section', {
        className: 'emoji'
      }, state.confirming ? state.original.emoji : props.emoji),
      e('section', {
        className: 'emoji-confirm ' +
            (state.confirming ? 'emoji-confirm-visible' : '')
      }, state.confirming.emoji),
      e('input', {
        type: 'password',
        className: 'master-password ' +
            (state.shake ? 'master-password-shake' : ''),
        placeholder: state.confirming ? 'Confirmation' : 'Master Password',
        value: state.confirming ? state.confirming.master : props.master,
        onChange: (e) => {
          const value = e.target.value;

          if (state.confirming) {
            this.setState(Object.assign({}, state, {
              confirming: {
                master: value,
                emoji: props.computeEmoji(value)
              }
            }));
          } else {
            props.onChange(value, props.computing);
          }
        },
        onKeyPress: (e) => {
          if (e.key !== 'Enter')
            return;
          e.preventDefault();

          let confirming = state.confirming;
          let revert = false;

          // TODO(indutny): present error
          if (confirming) {
            if (state.confirming.master.length === 0)
              revert = true;
            else if (!this.validateConfirmation())
              return;
          }

          if (!confirming)
            confirming = this.props.hasAppsForEmoji(props.emoji);

          this.setState(Object.assign({}, state, {
            original: {
              master: props.master,
              emoji: props.emoji
            },
            confirming: confirming ? false : {
              master: '',
              emoji: props.computeEmoji('')
            }
          }));

          if (confirming && !revert)
            return props.onSubmit();
        }
      })
    );
  }
}
module.exports = MasterPassword;
