'use strict';

var exec = require('cordova/exec');

var Sso = {
  line: {
    login: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'loginWithLine', [param]);
    },
  },
  twitter: {
    login: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'loginWithTwitter', [param]);
    } 
  }

};
module.exports = Sso;
