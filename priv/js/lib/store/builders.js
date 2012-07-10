var common = require('../common');
var bean = require('bean');
var deep = require('../deep');

exports.init = function(page, cb) {
    page.on('queue_size', function(_, queue_size) {
        var q = common.findBy(page.store.builders, 'name', queue_size.name);
        q.queue_size = queue_size.queue_size;
        bean.fire(q, 'update');
    });

    bean.add(page.store.builders, 'startUpdate', function() {
        page.req('builders', null, function(_, builders) {
            var changes = deep.update(page.store.builders, builders);
            if(changes.updated.length > 0 || changes.inserted.length > 0 || changes.deleted.length > 0) {
                bean.fire(page.store.builders, 'endUpdate', changes);
            }
        });
    });
    bean.fire(page.store.builders, 'startUpdate');
    cb(null);

};
