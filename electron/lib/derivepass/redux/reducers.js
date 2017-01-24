'use strict';

const redux = require('redux');

function application(state, action) {
  const p = action.payload;

  switch (action.type) {
    case 'SYNC_APPLICATION':
      if (!state) {
        return {
          uuid: p.uuid,

          domain: p.domain,
          login: p.login,
          revision: p.revision,

          index: p.index,
          master: p.master,
          removed: p.removed,
          changedAt: p.changedAt
        };
      }

      if (p.uuid !== state.uuid || p.changedAt <= state.changedAt)
        return state;

      return Object.assign({}, state, {
        domain: p.domain,
        login: p.login,
        revision: p.revision,

        index: p.index,
        removed: p.removed,
        changedAt: p.changedAt
      });
    case 'REMOVE_APPLICATION':
      if (p.uuid !== state.uuid || state.removed)
        return state;

      return Object.assign({}, state, {
        removed: true
      });
    case 'MOVE_APPLICATION':
      if (p.uuid !== state.uuid || p.newIndex === state.index)
        return state;

      return Object.assign({}, state, {
        index: p.newIndex
      });
    case 'UPDATE_APPLICATION':
      if (p.uuid !== state.uuid)
        return state;

      if (p.domain === state.domain &&
          p.login === state.login &&
          p.revision === state.revision) {
        return state;
      }

      return Object.assign({}, state, {
        domain: p.domain,
        login: p.login,
        revision: p.revision,

        changedAt: p.changedAt
      });
    default:
      return state;
  }
}

function applications(state = [], action) {
  switch (action.type) {
    case 'SYNC_APPLICATION':
      const found = state.some(app => app.uuid === action.payload.uuid);
      if (!found)
        return state.concat(application(undefined, action));

      return state.map(state => application(state, action));
    case 'REMOVE_APPLICATION':
    case 'MOVE_APPLICATION':
    case 'UPDATE_APPLICATION':
      return state.map(app => application(app, action));
    default:
      return state;
  }
}

module.exports = redux.combineReducers({
  applications: applications
});
