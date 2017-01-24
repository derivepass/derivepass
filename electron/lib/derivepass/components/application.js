'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

class Application extends React.Component {
  constructor() {
    super();

    // NOTE: Ideally, we could want to have separate redux store here
    this.state = {
      view: 'normal'
    };
  }

  render() {
    if (this.state.view === 'edit')
      return this.renderEdit();

    const props = this.props;

    const domain = e('p', { className: 'application-domain' },
                     props.app.domain);
    const login = e('p', { className: 'application-login' }, props.app.login);

    const edit = e('button', {
      className: 'application-edit',
      onClick: (e) => {
        e.stopPropagation();
        this.onEditClick();
      }
    }, '✏️');

    return e('article', {
      className: `application application-${this.state.view}`,
      onClick: () => {
        this.setState(Object.assign({}, this.state, { view: 'computing' }));
        this.props.copyPassword(props.master, this.props.app, () => {
          this.setState(Object.assign({}, this.state, { view: 'normal' }));
        });
      }
    }, domain, login, edit);
  }

  onEditClick() {
    if (this.state.view !== 'normal')
      return;

    this.setState(Object.assign({}, this.state, {
      fields: this.props.app,
      view: 'edit'
    }));
  }

  input(field) {
    return e('input', {
      className: `application-${field}`,
      type: field === 'revision' ? 'number' : 'text',
      onChange: (e) => this.onFieldChange(field, e.target.value),
      value: this.state.fields[field]
    });
  }

  onFieldChange(field, value) {
    if (field === 'revision')
      value = value.replace(/[^\d]+/g, '');

    this.setState(Object.assign({}, this.state, {
      fields: Object.assign({}, this.state.fields, { [field]: value })
    }));
  }

  renderEdit() {
    const props = this.props;

    const save = e('button', {
      className: 'application-save',
      onClick: (e) => {
        e.stopPropagation();
        const fields = this.state.fields;
        this.setState(Object.assign({}, this.state, { view: 'normal' }));
        this.props.onSave(fields);
      }
    }, '💾');

    return e('article', {
      className: 'application application-edit'
    }, this.input('domain'), this.input('login'), this.input('revision'), save);
  }
}
module.exports = Application;
