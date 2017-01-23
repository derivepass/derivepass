'use strict';

const assert = require('assert');

const binding = require('bindings')('scrypt_binding');

describe('scrypt/binding', () => {
  it('should scrypt', (cb) => {
    binding.scrypt(Buffer.from('hello'), Buffer.from('derivepass/aes'),
                   (256 + 512) / 8, (data) => {
      assert.strictEqual(
          data.toString('hex'),
          'dbc62b97c86f9061e6f1787bb4c669125b4f68eacb6ea91e8e04d798022' +
            '066f58a4193948bcd653476ba6ec41b2802ed41d43e032f87909af0c43e' +
            '0c2d25aa831cb21ae08254f3094c81e1e257f526f8edbbdb6099cfb0a0c' +
            '5556c0b228a96f2');
      cb();
    });
  });

  it('should derivepass', (cb) => {
    binding.derivepass('hello', 'gmail.com/test', (pass) => {
      assert.strictEqual(
          pass,
          'b4r5cMNCdcLJZ5aroCo5CGM7');
      cb();
    });
  });
});
