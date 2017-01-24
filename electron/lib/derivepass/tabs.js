'use strict';

const util = require('util');
const EventEmitter = require('events').EventEmitter;

function Button(elem) {
  EventEmitter.call(this);

  this.elem = elem;
  this.active = this.elem.classList.contains('tabs-button-active');

  this.elem.onclick = (e) => {
    e.preventDefault();
    if (this.active)
      return;

    this.emit('click');
  };
}
util.inherits(Button, EventEmitter);

Button.prototype.toggle = function toggle(on) {
  if (this.active === on)
    return;
  this.active = on;

  if (on)
    this.elem.classList.add('tabs-button-active');
  else
    this.elem.classList.remove('tabs-button-active');
};

function View(elem) {
  this.elem = elem;
  this.active = true;
}

View.prototype.toggle = function toggle(on) {
  this.active = on;
  this.elem.style = `display: ${on ? 'block' : 'none'}`;
};

View.prototype.show = function show() {
  this.toggle(true);
};

View.prototype.hide = function hide() {
  this.toggle(false);
};

function Tabs(header, content) {
  this.header = document.getElementById(header);
  this.content = document.getElementById(content);

  this.buttons = [];

  this.header.querySelectorAll('.tabs-button').forEach((elem) => {
    this.buttons.push(new Button(elem));
  });

  this.views = this.buttons.map((button) => {
    const elem = this.content.querySelector(button.elem.dataset.target);
    const view = new View(elem);
    view.toggle(button.active);
    return view;
  });

  this.buttons.forEach((button) => {
    button.on('click', () => {
      this.select(this.buttons.indexOf(button));
    });
  });
}
module.exports = Tabs;

Tabs.prototype.select = function select(index) {
  for (let i = 0; i < this.buttons.length; i++) {
    this.buttons[i].toggle(i === index);
    this.views[i].toggle(i === index);
  }
};
