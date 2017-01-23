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

  const apps = local.getApplications(emoji);

  this.content.innerHTML = '';

  apps.forEach((app) => {
    const container = document.createElement('div');
    container.className = 'application';
    container.id = app.uuid;
    container.textContent = app.get('domain') + ' > ' + app.get('login');

    container.onclick = (e) => {
      e.preventDefault();

      app.passwordFromMaster(this.master, (err, pass) => {
        if (err)
          throw err;

        electron.clipboard.writeText(pass);
        alert('Copied to clipboard');
      });

      return false;
    };

    this.content.appendChild(container);
  });
};

AppList.prototype.setMaster = function setMaster(emoji, master) {
  this.emoji = null;
  this.master = null;

  function onKeys(err) {
    if (err)
      throw err;

    this.emoji = emoji;
    this.master = master;
    this.reload();
  }

  cryptor.reset();
  clearTimeout(this.timer);
  this.timer = setTimeout(() => {
    this.cryptor.deriveKeys(master, onKeys);
  }, 250);
};
