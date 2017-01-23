'use strict';

const assert = require('assert');
const binding = require('bindings')('scrypt_binding');

function Cryptor() {
  this.aesKey = null;
  this.macKey = null;
}
module.exports = Cryptor;

Cryptor.prototype.setKeys = function setKeys(aes, mac) {
  this.aesKey = aes;
  this.macKey = mac;
};

Cryptor.prototype.reset = function reset() {
  this.aesKey = null;
  this.macKey = null;
};

Cryptor.prototype._checkKeys = function _checkKeys() {
  assert(this.aesKey !== null && this.macKey !== null,
         'Cryptor not initialized');
};

Cryptor.prototype.encrypt = function encrypt(value) {
  this._checkKeys();
  return value;
};

Cryptor.prototype.decrypt = function decrypt(value) {
  this._checkKeys();
  return value;
};

Cryptor.prototype.encryptNumber = function encryptNumber(value) {
  return this.encrypt(value.toString());
};

Cryptor.prototype.decryptNumber = function decryptNumber(value) {
  return parseInt(this.decrypt(value), 10);
};
