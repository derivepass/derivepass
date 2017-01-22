'use strict';

// Really dumb local cookie storage for CloudKit
function parse() {
  return JSON.parse(window.localStorage.getItem('web-cookies') || '{}');
}

Object.defineProperty(window.document, 'cookie', {
  enumerable: true,
  configurable: false,
  get: () => {
    const json = parse();

    const res = [];
    Object.keys(json).forEach(key => res.push(`${key}=${json[key]}`));
    return res.join('; ');
  },
  set: (cookie) => {
    const json = parse();

    cookie = cookie.replace(/;.*$/, '');

    const key = cookie.replace(/=.*$/, '');
    const value = cookie.replace(/^[^=]+=/, '');
    if (value === 'null')
      delete json[key];
    else
      json[key] = value;
    window.localStorage.setItem('web-cookies', JSON.stringify(json));
  }
});
