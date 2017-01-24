'use strict';

const assert = require('assert');
const crypto = require('crypto');
const Buffer = require('buffer').Buffer;
const Cryptor = require('../').Cryptor;

describe('Crypto', () => {
  it('should support old format', () => {
    const aes = Buffer.from([
      0xe3, 0x3b, 0x22, 0x21, 0xd5, 0x1d, 0xe5, 0xb5,
      0x92, 0x17, 0xd9, 0xea, 0x05, 0x83, 0x25, 0xa5,
      0x1d, 0x3b, 0x32, 0x93, 0x06, 0xcd, 0x1c, 0x98,
      0x61, 0xaa, 0x5e, 0x17, 0xee, 0xef, 0x16, 0x71 ]);
    const mac = Buffer.from([
      0x8a, 0x41, 0x93, 0x94, 0x8b, 0xcd, 0x65, 0x34, 0x76, 0xba, 0x6e,
      0xc4, 0x1b, 0x28, 0x02, 0xed, 0x41, 0xd4, 0x3e, 0x03, 0x2f, 0x87,
      0x90, 0x9a, 0xf0, 0xc4, 0x3e, 0x0c, 0x2d, 0x25, 0xaa, 0x83, 0x1c,
      0xb2, 0x1a, 0xe0, 0x82, 0x54, 0xf3, 0x09, 0x4c, 0x81, 0xe1, 0xe2,
      0x57, 0xf5, 0x26, 0xf8, 0xed, 0xbb, 0xdb, 0x60, 0x99, 0xcf, 0xb0,
      0xa0, 0xc5, 0x55, 0x6c, 0x0b, 0x22, 0x8a, 0x96, 0xf2 ]);

    const c = new Cryptor();
    c.aesKey = aes;
    c.macKey = mac;

    const old = Buffer.from(
      '7bc85a06f6cbc315e27696c4e648c46e217c12946299522583773907c6bf32b4',
      'hex');

    assert.strictEqual(c.decrypt(old), 'ohai');
  });

  it('should cycle', () => {
    const aes = crypto.randomBytes(32);
    const mac = crypto.randomBytes(64);

    const c = new Cryptor();
    c.aesKey = aes;
    c.macKey = mac;

    assert.strictEqual(c.decrypt(c.encrypt('ohai')), 'ohai');
    assert.strictEqual(c.decryptNumber(c.encryptNumber(42)), 42);
  });

  it('should not reuse IV', () => {
    const aes = crypto.randomBytes(32);
    const mac = crypto.randomBytes(64);

    const c = new Cryptor();
    c.aesKey = aes;
    c.macKey = mac;

    assert.notEqual(c.encrypt('ohai').toString('hex'),
                    c.encrypt('ohai').toString('hex'));
  });

  it('should generate password', (cb) => {
    const c = new Cryptor();

    c.derivePassword('hello', {
      domain: 'gmail.com',
      login: 'test',
      revision: 1
    }, (err, pass) => {
      assert(!err);
      assert.strictEqual(pass, 'b4r5cMNCdcLJZ5aroCo5CGM7');

      c.derivePassord('hello', {
        domain: 'gmail.com',
        login: 'test',
        revision: 2
      }, (err, pass) => {
        assert(!err);
        assert.strictEqual(pass, '.Tzt73chSH7xCo_dvz_eraC_');

        cb();
      });
    });
  });
});
