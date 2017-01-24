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

      if (p.uuid !== state.uuid || p.changedAt < state.changedAt)
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
      let found = false;

      const res = state.map((state) => {
        const res = application(state, action);
        if (res !== state)
          found = true;
        return res;
      });

      if (found)
        return res;
      return res.concat(application(undefined, action));
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
