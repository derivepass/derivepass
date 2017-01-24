'use strict';

const React = require('react');

const derivepass = require('../../derivepass');

const e = React.createElement;

const EMPTY_APP = {
  domain: '',
  login: '',
  revision: 1
};

class Application extends React.Component {
  constructor(props) {
    super(props);

    // NOTE: Ideally, we could want to have separate redux store here
    if (props.app === null) {
      this.state = {
        fields: EMPTY_APP,
        view: 'edit'
      };
    } else {
      this.state = { view: 'normal' };
    }
  }

  render() {
    if (this.state.view === 'edit')
      return this.renderEdit();

    const props = this.props;

    const domain = e('p', { className: 'application-domain' },
                     props.app.domain);
    const login = e('p', { className: 'application-login' }, props.app.login);

    const edit = e('button', {
      className: 'application-edit application-button',
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

  input(label, field, placeholder) {
    return e('section', { className: 'application-field' },
      e('label', { className: 'application-field-label' },
        e('span', {}, label),
        e('input', {
          className: `application-${field}`,
          type: field === 'revision' ? 'number' : 'text',
          onChange: (e) => this.onFieldChange(field, e.target.value),
          value: this.state.fields[field],
          placeholder: placeholder
        })),
      e('div', { className: 'clear' }));
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

    const isNew = props.app === null;

    const save = e('button', {
      className: 'application-save application-button',
      onClick: (e) => {
        e.stopPropagation();
        const fields = this.state.fields;

        // TODO(indutny): present error
        if (fields.domain.length === 0 ||
            fields.login.length === 0 ||
            (fields.revision | 0) < 1) {
          return;
        }

        if (isNew) {
          this.setState(Object.assign({}, this.state, {
            fields: EMPTY_APP,
            view: 'edit'
          }));
          this.props.onCreate(fields);
        } else {
          this.setState(Object.assign({}, this.state, { view: 'normal' }));
          this.props.onSave(fields);
        }
      }
    }, '💾');

    const remove = !isNew && e('button', {
      className: 'application-remove application-button',
      onClick: (e) => {
        e.stopPropagation();
        this.props.onRemove();
      }
    }, '🗑');

    const title = isNew && e('h3', {}, 'New Application');

    return e('article', {
      className: 'application application-edit'
    }, title,
       this.input('Domain:', 'domain', 'gmail.com'),
       this.input('Login:', 'login', 'username'),
       this.input('Revision:', 'revision'),
       save, remove);
  }
}
module.exports = Application;
