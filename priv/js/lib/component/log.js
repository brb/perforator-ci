var t = require('../templates');
var w = require('../window');
var v = require('valentine');
var qwery = require('qwery');
var step = require('step');
var bean = require('bean');
var bonzo = require('bonzo');
var moment = require('moment');
var common = require('../common');

exports.init = function(page, cb) {
    page.handle('/', function() {
        if(page.projectId) {
            page.go('/' + page.projectId);
        } else {
            page.go('/1');
        }
    });
    page.handle(/^\/(.+)$/, function(from, to, params) {
        step(function() {
            page.req('builds', page.projectId, this.parallel());
            page.req('project', page.projectId, this.parallel());
        }, function(err, builds, project) {
            if(err) {
                page.body.html(t.error.render({
                    title : 'No projects found'
                }));
                return;
            }
            var offs = [];
            offs.push(page.on('build_finished', function(_, buildFinished) {
                if(buildFinished.project_id === project.id) {
                    var build = common.findById(builds, buildFinished.build_id);
                    build.finished = true;
                    build.succeeded = buildFinished.success;
                    // TODO this is fishy - when is build.buildInit undefined?
                    build.time = (buildFinished.timestamp - (build.buildInit ? build.buildInit.timestamp : 0)) * 1000;
                    build.origTime = build.time;
                    build.time += ' ms';
                    if(build.previous) {
                        build.timeDelta = build.origTime - build.previous.origTime;
                        build.timeDelta += ' ms';
                    }
                    w.el('build-' + build.id).replaceWith(t.logBuild.render(build, t));
                    attachClickHandler(w.el('build-' + build.id)[0]);
                }
            }));
            offs.push(page.on('build_init', function(_, buildInit) {
                if(buildInit.project_id === project.id) {
                    var build = {
                        previous : builds[0] || null,
                        buildInit : buildInit,
                        id : buildInit.build_id,
                        commit_id : buildInit.commit_id,
                        started : moment(new Date(buildInit.timestamp * 1000)).format('LLLL'),
                        finished : false,
                        modules : '',
                        tests : ''
                    };
                    w.el('builds').prepend(t.logBuild.render(build, t));
                    attachClickHandler(w.el('build-' + build.id)[0]);
                    builds.unshift(build);
                }
            }));
            page.beforego(function(from, to) {
                v.each(offs, function(off) {
                    off();
                });
            });
            var buildLag = null;

            builds.reverse();
            v.each(builds, function(build) {
                build.origTime = build.time;
                build.time += ' ms';
                if(buildLag === null) {
                    build.timeDelta = null;
                } else {
                    build.timeDelta = (build.origTime - buildLag.origTime) + ' ms';
                }
                buildLag = build;
            });
            builds.reverse();

            v.each(builds, function(build) {
                build.started = moment(new Date(build.started * 1000)).format('LLLL');
            });
            page.body.html(t.log.render({
                builds : builds,
                project : project
            }, t));
            var attachClickHandler = function(row) {
                if(row.parentNode.nodeName.toLowerCase() === 'thead') {
                    return;
                }
                bean.add(row, 'click', function() {
                    page.go('/' + project.id + '/build/' + bonzo(row).data('id'));
                });
            };
            v.each(qwery('tr'), attachClickHandler);
        });
    });
    cb();
};
