/*global cordova*/

var exec = require("cordova/exec");

var MicAccess = function(){};

MicAccess.prototype.gitMicBuffer = function(callback) {
    cordova.exec(callback, function(err) {
        callback('Error.');
    }, "MicAccess", "getBuffer", []);
};


module.exports = new MicAccess();
