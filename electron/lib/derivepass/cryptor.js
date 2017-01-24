'use strict';

const assert = require('assert');
const crypto = require('crypto');
const binding = require('bindings')('scrypt_binding');
const Buffer = require('buffer').Buffer;

const SCRYPT_AES_DOMAIN = Buffer.from('derivepass/aes');
const AES_KEY_SIZE = 32;
const IV_SIZE = 16;
const MAC_KEY_SIZE = 64;
const MAC_SIZE = 32;

function Cryptor() {
  this.aesKey = null;
  this.macKey = null;
}
module.exports = Cryptor;

Cryptor.prototype.derivePassword = function derivePassword(master, app, cb) {
  let text = `${app.domain}/${app.login}`;
  if (app.revision > 1)
    text += `#${app.revision}`;
  binding.derivepass(master, text, pass => cb(null, pass));
};

Cryptor.prototype.deriveKeys = function deriveKeys(password, cb) {
  binding.scrypt(
    Buffer.from(password),
    SCRYPT_AES_DOMAIN,
    AES_KEY_SIZE + MAC_KEY_SIZE,
    (res) => {
      this.aesKey = res.slice(0, AES_KEY_SIZE);
      this.macKey = res.slice(AES_KEY_SIZE);
      assert.strictEqual(this.aesKey.length, AES_KEY_SIZE);
      assert.strictEqual(this.macKey.length, MAC_KEY_SIZE);
      cb(null);
    });
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

  const iv = crypto.randomBytes(IV_SIZE);
  const cipher = crypto.createCipheriv('aes-256-cbc', this.aesKey, iv);

  const content = Buffer.concat([
    iv,
    cipher.update(value),
    cipher.final()
  ]);

  const mac = crypto.createHmac('sha256', this.macKey).update(content).digest();

  return 'v1:' + content.toString('hex') + mac.toString('hex');
};

Cryptor.prototype.decrypt = function decrypt(value) {
  this._checkKeys();

  let version = 0;
  if (/^v1:/.test(value)) {
    version = 1;
    value = value.slice(3);
  }

  value = Buffer.from(value, 'hex');

  if (version === 1) {
    assert(value.length > IV_SIZE + MAC_SIZE);

    const actual = crypto.createHmac('sha256', this.macKey)
        .update(value.slice(0, value.length - MAC_SIZE))
        .digest();
    const mac = value.slice(value.length - MAC_SIZE);
    try {
      assert.equal(actual.toString('hex'), mac.toString('hex'),
                   'MAC mismatch');
    } catch (e) {
      console.error(e);
      return '<decrypt failed>';
    }

    value = value.slice(0, value.length - MAC_SIZE);
  }

  const iv = value.slice(0, IV_SIZE);
  const content = value.slice(IV_SIZE);

  const d = crypto.createDecipheriv('aes-256-cbc', this.aesKey, iv);

  try {
    return d.update(content) + d.final();
  } catch (e) {
    console.error(e);
    return '<decrypt failed>';
  }
};

Cryptor.prototype.encryptNumber = function encryptNumber(value) {
  return this.encrypt(value.toString());
};

Cryptor.prototype.decryptNumber = function decryptNumber(value) {
  return this.decrypt(value) | 0;
};
