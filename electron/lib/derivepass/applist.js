'use strict';

function AppList(id) {
  this.content = document.getElementById(id);
}
module.exports = AppList;

AppList.prototype.setApplications = function setApplications(list, master) {
  this.content.textContent = JSON.stringify(list);
};
