var bean = require('bean');
var reqwest = require('reqwest');
var w = require('./window');
var common = require('./common');
var p = require('page');

exports.create = function(socket) {
    var previousPath = null;
    var page = {
        start : function() {
            p({
                click : true,
                popstate : true,
                dispatch : true
            });
            this.go(w.getPath());
        },
        store : {
            builders : []
        },
        once : function(event, handler) {
            bean.one(socket, event, function(err, msg) {
                console.log('page.once', event, err, msg);
                handler(err, msg);
            });
        },
        on : function(event, handler) {
            var handlerWrapper = function(err, msg) {
                console.log('page.on', event, err, msg);
                handler(err, msg);
            };
            bean.add(socket, event, handlerWrapper);
            return function() {
                bean.remove(socket, event, handlerWrapper);
            };
        },
        emit : function(event, err, msg) {
            console.log('page.emit', event, err, msg);
            socket.send(JSON.stringify({
                err : err,
                msg : msg,
                type : event
            }));
        },
        req : function(resource, msg, cb) {
            console.log('page.req', resource, msg);
            cb = cb || function(){};
            var data = JSON.stringify(msg);
            reqwest({
                url : '/api/1/' + resource,
                method : 'post',
                type : 'json',
                data : data,
                contentType: 'application/json',
                error : function(xhr) {
                    throw new common.error({
                        error : xhr.status + ' ' + xhr.statusText,
                        message : 'tried to send ' + resource + ' this: ' + data
                    });
                },
                success : function(resp) {
                    console.log('resp', resp);
                    if(resp.err) {
                        cb(resp, null);
                    } else {
                        cb(null, resp.msg);
                    }
                }
            });
        },
        body : w.el('body'),
        projectId : null,
        handle : function(path, cb) {
            var self = this;
            console.log('adding handler', path);
            p(path, function(ctx) {
                setTimeout(function() {
                    var nextPath = w.getPath();
                    if(previousPath !== nextPath) {
                        console.log('handling', previousPath, nextPath);
                        bean.fire(self, 'page', [previousPath, nextPath, ctx.params]);
                        cb(previousPath, nextPath, ctx.params);
                        previousPath = nextPath;
                    }
                }, 0);
            });
        },
        beforego : function(cb) {
            bean.one(this, 'page', cb);
        },
        go : function(path) {
            p(path);
        }
    };
    bean.add(page, 'page', function(from, to, params) {
        if(params.length > 0) {
            var projectId = params[0];
            if(projectId !== page.projectId) {
                page.projectId = projectId;
                bean.fire(page, 'projectId');
            }
            params.shift();
        }
    });
    return page;
};
