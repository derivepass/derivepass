'use strict';

function AppList(id) {
  this.content = document.getElementById(id);
}
module.exports = AppList;

AppList.prototype.setApplications = function setApplications(list) {
  this.content.textContent = list.map((app) => {
    return app.get('domain') + '|' + app.get('login');
  }).join('\n');
};
