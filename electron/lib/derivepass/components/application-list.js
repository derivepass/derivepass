'use strict';

const electron = require('electron');
const React = require('react');

const derivepass = require('../../derivepass');
const Application = derivepass.components.Application;

const e = React.createElement;

class ApplicationList extends React.Component {
  constructor() {
    super();

    this.state = { computing: false };
  }

  render() {
    const cryptor = this.props.cryptor;
    const master = this.props.master;

    const suffix = this.state.computing ? 'computing' : 'idle';

    return e('section', {
      className: `application-list application-list-${suffix}`
    }, this.props.applications.map((app) => {
      const domain = cryptor.decrypt(app.domain);
      const login = cryptor.decrypt(app.login);
      const revision = cryptor.decryptNumber(app.revision);

      return e(Application, {
        key: app.uuid,
        app: {
          domain: domain,
          login: login
        },
        onClick: () => {
          this.setState({ computing: true });
          cryptor.passwordFromMaster(master, domain, login, revision, (err,
                                                                       p,ass) => {
            if (err)
              throw err;

            electron.clipboard.writeText(p);
            this.setState({ computing: false });
          });
        }
      });
    }));
  }
}
module.exports = ApplicationList;
