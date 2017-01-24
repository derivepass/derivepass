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
