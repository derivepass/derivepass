'use strict';

const electron = require('electron');

function AppList(id, options) {
  this.content = document.getElementById(id);
  this.cryptor = options.cryptor;
  this.local = options.local;
  this.remote = options.remote;

  this.local.on('update', () => {
    this.reload();
  });

  this.timer = null;

  this.emoji = null;
  this.master = null;
}
module.exports = AppList;

AppList.prototype.reload = function reload() {
  if (this.emoji === null || this.master === null)
    return;

  const apps = this.local.getApplications(this.emoji);

  this.content.innerHTML = '';

  apps.forEach((app) => {
    const container = document.createElement('article');
    container.className = 'application';
    container.id = app.uuid;

    const domain = document.createElement('div');
    domain.className = 'application-domain';
    domain.textContent = app.get('domain');

    const login = document.createElement('div');
    login.className = 'application-login';
    login.textContent = app.get('login');

    const copy = document.createElement('button');
    copy.className = 'application-buttons-button application-buttons-copy';
    copy.textContent = '📋';

    const remove = document.createElement('button');
    remove.className = 'application-buttons-button application-buttons-remove';
    remove.textContent = 'X';

    const edit = document.createElement('button');
    edit.className = 'application-buttons-button application-buttons-edit';
    edit.textContent = '✏️';

    const buttons = document.createElement('div');
    buttons.className = 'application-buttons';
    buttons.appendChild(copy);
    buttons.appendChild(edit);
    buttons.appendChild(remove);

    container.appendChild(buttons);
    container.appendChild(domain);
    container.appendChild(login);

    copy.onclick = (e) => {
      e.preventDefault();
      copy.disabled = true;

      app.passwordFromMaster(this.master, (err, pass) => {
        copy.disabled = false;
        if (err)
          throw err;

        electron.clipboard.writeText(pass);
        alert('Copied to clipboard');
      });

      return false;
    };

    remove.onclick = (e) => {
      e.preventDefault();

      this.content.removeChild(container);

      app.set('removed', true);
      this.local.save();
    };

    this.content.appendChild(container);
  });
};

AppList.prototype.setMaster = function setMaster(emoji, master) {
  this.emoji = null;
  this.master = null;
  this.cryptor.reset();

  clearTimeout(this.timer);
  this.timer = setTimeout(() => {
    this.cryptor.deriveKeys(master, (err) => {
      if (err)
        throw err;

      this.emoji = emoji;
      this.master = master;
      this.reload();
    });
  }, 250);
};
