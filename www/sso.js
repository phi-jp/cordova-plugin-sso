'use strict';

var exec = require('cordova/exec');

var Sso = {
  line: {
    login: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'loginWithLine', [param]);
    },
    logout: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'logoutWithLine', [param]);
    },
  },
  twitter: {
    login: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'loginWithTwitter', [param]);
    },
    logout: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'logoutWithTwitter', [param]);
    }, 
  },
  facebook: {
    login: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'loginWithFacebook',[param]);
    },
    logout: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'logoutWithFacebook', [param]);
    },
  },
  google: {
    login: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'loginWithGoogle',[param]);
    },
    logout: function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Sso', 'logoutWithGoogle',[param]);
    },
  }

};
module.exports = Sso;
