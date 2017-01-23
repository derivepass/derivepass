'use strict';

function Application(uuid, json, cryptor) {
  this.cryptor = cryptor;
  this.uuid = uuid;
  this.json = {};
  this.changed = false;
}
module.exports = Application;

Application.prototype.set = function set(key, value) {
  if (key === 'domain' || key === 'login')
    value = this.cryptor.encrypt(value);
  else if (key === 'revision')
    value = this.cryptor.encryptNumber(value);

  return this.setRaw(key, value);
};

Application.prototype.setRaw = function setRaw(key, value) {
  if (this.json[key] === value)
    return;
  this.changed = true;

  if (key !== 'changedAt')
    this.json.changedAt = +new Date;
  this.json[key] = value;
};

Application.prototype.get = function get(key) {
  const res = this.getRaw(key);

  if (key === 'domain' || key === 'login')
    return this.cryptor.decrypt(res);
  else if (key === 'revision')
    return this.cryptor.decryptNumber(res);
  else
    return res;
};

Application.prototype.getRaw = function getRaw(key) {
  return this.json[key];
};

Application.prototype.toJSON = function toJSON() {
  return this.json;
};