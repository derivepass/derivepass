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
          changedAt: p.changedAt,

          view: {
            state: 'NORMAL'
          }
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
    case 'TOGGLE_APPLICATION_VIEW':
      if (p.uuid !== state.uuid)
        return state;

      return Object.assign({}, state, {
        view: { state: p.state }
      });
    default:
      return state;
  }
}

function applications(state = { list: [] }, action) {
  switch (action.type) {
    case 'SYNC_APPLICATION':
      const found = state.list.some(app => app.uuid === action.payload.uuid);
      if (!found) {
        return Object.assign({}, state, {
          list: state.list.concat(application(undefined, action))
        });
      }

      return Object.assign({}, state, {
        list: state.list.map(state => application(state, action))
      });
    case 'REMOVE_APPLICATION':
    case 'MOVE_APPLICATION':
    case 'UPDATE_APPLICATION':
    case 'TOGGLE_APPLICATION_VIEW':
      return Object.assign({}, state, {
        list: state.list.map(app => application(app, action))
      });
    default:
      return state;
  }
}

function master(state, action) {
  const p = action.payload;

  if (state === undefined) {
    state = {
      password: '',
      emoji: '😬',
      computing: 'PENDING'
    };
  }

  switch (action.type) {
    case 'UPDATE_MASTER':
      return Object.assign({}, state, {
        password: p.password,
        emoji: p.emoji
      });
    case 'SET_MASTER_COMPUTING':
      return Object.assign({}, state, { computing: p.value });
    default:
      return state;
  }
}

function tab(state = { active: 'MASTER' }, action) {
  switch (action.type) {
    case 'SELECT_TAB':
      return { active: action.payload.id };
    default:
      return state;
  }
}

module.exports = redux.combineReducers({
  master: master,
  tab: tab,
  applications: applications
});
