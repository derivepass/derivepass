'use strict';

const electron = require('electron');

function AppList(id) {
  this.content = document.getElementById(id);
}
module.exports = AppList;

AppList.prototype.setApplications = function setApplications(list, master) {
  this.content.innerHTML = '';

  list.forEach((app) => {
    const container = document.createElement('div');
    container.id = app.uuid;
    container.textContent = app.get('domain') + ' > ' + app.get('login');

    container.onclick = (e) => {
      e.preventDefault();

      app.passwordFromMaster(master, (err, pass) => {
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
