'use strict';

exports.syncApplication = (info) => {
  return { type: 'SYNC_APPLICATION', payload: info };
};

exports.removeApplication = (uuid, changedAt) => {
  return { type: 'REMOVE_APPLICATION', payload: { uuid, changedAt } };
};

exports.moveApplication = (uuid, newIndex, changedAt) => {
  return { type: 'MOVE_APPLICATION', payload: { newIndex, changedAt } };
};

exports.updateApplication = (uuid, info) => {
  return {
    type: 'UPDATE_APPLICATION',
    payload: {
      uuid: uuid,
      domain: info.domain,
      login: info.login,
      revision: info.revision,

      changedAt: info.now
    }
  };
};

exports.updateMaster = (password, emoji) => {
  return {
    type: 'UPDATE_MASTER',
    payload: { password, emoji }
  };
};

exports.setMasterComputing = (status, emoji) => {
  return { type: 'SET_MASTER_COMPUTING', payload: { status, emoji } };
};

exports.selectTab = (id) => {
  return {
    type: 'SELECT_TAB',
    payload: { id: id }
  };
};
