'use strict';

function Application(uuid, json) {
  this.uuid = uuid;
  this.json = {};
  this.changed = false;
}
module.exports = Application;

Application.prototype.set = function set(key, value) {
  if (this.json[key] === value)
    return;
  this.changed = true;

  if (key !== 'changedAt')
    this.json.changedAt = +new Date;
  this.json[key] = value;
};

Application.prototype.get = function get(key) {
  return this.json[key];
};

Application.prototype.toJSON = function toJSON() {
  return this.json;
};
