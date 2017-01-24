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
        removed: true,
        changedAt: p.changedAt
      });
    case 'MOVE_APPLICATION':
      if (p.uuid !== state.uuid || p.newIndex === state.index)
        return state;

      return Object.assign({}, state, {
        index: p.newIndex,
        changedAt: p.changedAt
      });
    case 'UPDATE_APPLICATION':
      if (p.uuid !== state.uuid)
        return state;

      if (p.changedAt === state.changedAt)
        return state;

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
      computing: {
        status: 'PENDING',
        emoji: ''
      }
    };
  }

  switch (action.type) {
    case 'UPDATE_MASTER':
      return Object.assign({}, state, {
        password: p.password,
        emoji: p.emoji
      });
    case 'SET_MASTER_COMPUTING':
      return Object.assign({}, state, {
        computing: { status: p.status, emoji: p.emoji }
      });
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
