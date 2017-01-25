'use strict';

process.env.NODE_ENV = 'production';

const assert = require('assert');
const path = require('path');
const url = require('url');
const querystring = require('querystring');
const electron = require('electron');
const createMenubar = require('menubar');

const menubar = createMenubar({
  preloadWindow: true,
  dir: __dirname,
  icon: path.join(__dirname, 'icons', 'app.png')
});

let authQueue = [];

menubar.on('ready', () => {
  electron.ipcMain.on('do-auth', (event, uri) => {
    const popup = new electron.BrowserWindow({
      center: true,
      webPreferences: {
        nodeIntegration: false
      },
      width: 320,
      height: 420
    });

    menubar.hideWindow();
    popup.loadURL(uri);
    authQueue.push({ sender: event.sender, popup: popup });
  });

  electron.protocol.registerFileProtocol(
      'cloudkit-icloud.com.indutny.derivepass',
      (req, callback) => {
        const uri = url.parse(req.url);
        const qs = querystring.parse(uri.query);

        callback({ path: 'about:blank' });

        const queue = authQueue;
        authQueue = [];
        queue.forEach((item) => {
          item.popup.close();
          menubar.showWindow();
          item.sender.send('auth', qs);
        });
      });
});

menubar.on('after-create-window', () => {
  if (process.env.NODE_ENV !== 'production')
    menubar.window.webContents.openDevTools({ mode: 'detach' });
});
