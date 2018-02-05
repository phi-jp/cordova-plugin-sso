'use strict';

var exec = require('cordova/exec');

var Sso = {
  line: {
    login: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'loginWithLine', [param]);
    },
  }

};
module.exports = Sso;
