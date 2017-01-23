'use strict';

function AppList(id) {
  this.content = document.getElementById(id);
}
module.exports = AppList;

AppList.prototype.setApplications = function setApplications(list) {
  this.content.content = '';

  list.forEach((app) => {
    const container = document.createElement('div');
    container.id = app.uuid;
    container.textContent = app.get('domain') + ' > ' + app.get('login');

    this.content.appendChild(container);
  });
};
