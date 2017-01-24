'use strict';

exports.syncApplication = (info) => {
  return { type: 'SYNC_APPLICATION', payload: info };
};

exports.removeApplication = (uuid) => {
  return { type: 'REMOVE_APPLICATION', payload: { uuid } };
};

exports.moveApplication = (uuid, newIndex) => {
  return { type: 'MOVE_APPLICATION', payload: { newIndex } };
};

exports.updateApplication = (uuid, info) => {
  return {
    type: 'UPDATE_APPLICATION',
    payload: {
      domain: info.domain,
      login: info.login,
      revision: info.revision
    }
  };
};

exports.toggleApplicationView = (uuid, state) => {
  return {
    type: 'TOGGLE_APPLICATION_VIEW',
    payload: { uuid, state }
  };
};

exports.updateMaster = (password, emoji) => {
  return {
    type: 'UPDATE_MASTER',
    payload: { password, emoji }
  };
};

exports.setMasterComputing = (value) => {
  return { type: 'SET_MASTER_COMPUTING', payload: { value } };
};

exports.selectTab = (id) => {
  return {
    type: 'SELECT_TAB',
    payload: { id: id }
  };
};
