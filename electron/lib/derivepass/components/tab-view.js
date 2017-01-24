'use strict';

const React = require('react');
const derivepass = require('../../derivepass');

const e = React.createElement;

class TabView extends React.Component {
  render() {
    const buttons = [];
    const views = [];

    this.props.views.forEach((item) => {
      const suffix = item.id === this.props.active ? 'active' : 'inactive';

      const button = e('button', {
        key: item.id,
        className: `tab-view-nav-button tab-view-nav-button-${suffix}`,
        onClick: () => this.props.onClick(item.id)
      }, item.title);

      const view = e('article', {
        key: item.id,
        className: `tab-view-content-view tab-view-content-view-${suffix}`
      }, item.elem);

      buttons.push(button);
      views.push(view);
    });

    const nav = e('nav', { className: 'tab-view-nav' }, buttons);
    const content = e('section', { className: 'tab-view-content' }, views);

    return e('section', { className: 'tab-view' }, nav, content);
  }
}
module.exports = TabView;
