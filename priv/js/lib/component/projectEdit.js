var t = require('../templates');
var w = require('../window');
var common = require('../common');
var v = require('valentine');
var qwery = require('qwery');
var bean = require('bean');
var bonzo = require('bonzo');
var moment = require('moment');

exports.init = function(page, cb) {
    var gather = function() {
        var ondemand = w.el('ondemand').attr('checked');
        return {
            id : w.el('id').val(),
            repo_url : w.el('repo_url').val(),
            branch : w.el('branch').val(),
            build_instructions : v.reject(v.map(w.el('build_instructions').val().split('\n'), v.trim), v.is.emp),
            polling_strategy : (ondemand ? 'ondemand' : {
                time : parseInt(bonzo(qwery('#time')).val(), 10)
            })
        };
    };
    var augment = function() {
        bean.add(w.el('ondemand')[0], 'click', function() {
            console.log('click', gather());
            if(gather().polling_strategy === 'ondemand') {
                w.el('time').attr('disabled', 'disabled');
            } else {
                w.el('time').removeAttr('disabled');
            }
        });
    };
    var adaptToRender = function(project) {
        return {
            id : project.id,
            repo_url : project.repo_url,
            branch : project.branch,
            build_instructions : project.build_instructions.join('\n'),
            ondemand : project.polling_strategy === 'ondemand',
            polling_strategy : project.polling_strategy
        };
    };
    page.handle(/^\/add$/, function() {
        page.body.html(t.projectEdit.render({
            project : adaptToRender({
                id : 'Perforator',
                repo_url : 'file:///home/tahu/Desktop/PERFORATOR',
                branch : 'origin/master',
                build_instructions : [ './rebar get-deps', './rebar compile', './rebar perf' ],
                polling_strategy : 'ondemand'
            }),
            action : 'Add project'
        }, t));
        augment();
        bean.add(qwery('form')[0], 'submit', function(e) {
            var project = gather();
            page.req('project/new', project, function(err) {
                if(err) {
                    throw common.error(err);
                }
                bean.fire(page, 'projectAdded', [project]);
                page.go('/' + project.id);
            });
            e.preventDefault();
        });
    });
    page.handle(/^\/(.+)\/edit$/, function(from, to, params) {
        page.req('project', page.projectId, function(err, project) {
            if(err) {
                throw common.error(err);
            }
            page.body.html(t.projectEdit.render({
                project : adaptToRender(project),
                action : 'Save project'
            }, t));
            augment();
            bean.add(qwery('form')[0], 'submit', function(e) {
                var p = gather();
                p.id = project.id;
                page.req('project/update', p);
                bean.fire(page, 'projectUpdated', [p]);
                page.go('/' + p.id);
                e.preventDefault();
            });
        });
    });
    cb();
};
