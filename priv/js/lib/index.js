var domready = require('domready');
var step = require('step');
var bean = require('bean');

var t = require('./templates');
var w = require('./window');
var page = require('./page');

var storeBuilders = require('./component/storeBuilders');
var log = require('./component/log');
var run = require('./component/run');
var test = require('./component/test');
var projectEdit = require('./component/projectEdit');
var compare = require('./component/compare');
var sidebar = require('./component/sidebar');

step(function() {
    var socket = w.createSocket();
    this.parallel()(null, page.create(socket));
    socket.onmessage = function(event) {
        event = JSON.parse(event.data.toString());
        bean.fire(socket, event.type, [event.err, event.msg]);
    };
    socket.onopen = this.parallel();

    domready(this.parallel());
}, function(_, page) {
    page.handle('/static/COPYING', function() {
        w.setHref('/static/COPYING');
    });

    // the order is important
    storeBuilders.init(page, this.parallel());
    run.init(page, this.parallel());
    test.init(page, this.parallel());
    projectEdit.init(page, this.parallel());
    compare.init(page, this.parallel());
    log.init(page, this.parallel());
    sidebar.init(page, this.parallel());

    page.start();
});
