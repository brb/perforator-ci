var t = require('./templates');
var domready = require('domready');
var log = require('./log');
var run = require('./run');
var test = require('./test');
var projectEdit = require('./projectEdit');
var compare = require('./compare');
var bean = require('bean');
var w = require('./window');
var page = require('./page');
var step = require('step');
var storeBuilders = require('./store/builders');
var sidebar = require('./sidebar');

step(function() {
    var socket = w.createSocket();
    this.parallel()(null, page.create(socket));
    domready(this.parallel());
    socket.onmessage = function(event) {
        event = JSON.parse(event.data.toString());
        bean.fire(socket, event.type, [event.err, event.msg]);
    };
    socket.onopen = this.parallel();
}, function(_, page) {
    page.handle('/static/COPYING', function() {
        w.setHref('/static/COPYING');
    });
    storeBuilders.init(page, this.parallel());
    run.init(page, this.parallel());
    test.init(page, this.parallel());
    projectEdit.init(page, this.parallel());
    compare.init(page, this.parallel());
    // log should be initialized last, otherwise it could take over /project/*
    // url from projectEdit (/project/add)
    log.init(page, this.parallel());
    sidebar.init(page, this.parallel());
    page.start();
});
