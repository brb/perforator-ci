var humane = require('humane-js');

exports.notify = function(message) {
    console.log('NOTIFY', message);
    // TODO also, dream about desktop notifications?
    // http://www.html5rocks.com/en/tutorials/notifications/quick/
    humane.log(message);
};
exports.error = function(err) {
    exports.notify('Error ' + err.err + ': ' + err.msg);
    return err;
};

exports.findById = function(arr, id) {
    return exports.findBy(arr, 'id', id);
};
exports.findBy = function(arr, key, val) {
    for(var i = 0; i < arr.length; i += 1) {
        if(arr[i][key] === val) {
            return arr[i];
        }
    }
    return null;
};
