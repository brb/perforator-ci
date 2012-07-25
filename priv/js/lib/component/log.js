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
        }, function(err, runs, project) {
            if(err) {
                page.body.html(t.error.render({
                    title : 'No projects found'
                }));
                return;
            }
            var offs = [];
            offs.push(page.on('build_finished', function(_, buildFinished) {
                if(buildFinished.project_id === project.id) {
                    var run = common.findById(runs, buildFinished.build_id);
                    run.finished = true;
                    run.succeeded = buildFinished.success;
                    run.time = (buildFinished.timestamp - (run.buildInit ? run.buildInit.timestamp : 0)) * 1000; // TODO this is fishy - when is run.buildInit undefined?
                    run.origTime = run.time;
                    run.time += ' ms';
                    if(run.previous) {
                        run.timeDelta = run.origTime - run.previous.origTime;
                        run.timeDelta += ' ms';
                    }
                    w.el('run-' + run.id).replaceWith(t.logRun.render(run, t));
                    attachClickHandler(w.el('run-' + run.id)[0]);
                }
            }));
            offs.push(page.on('build_init', function(_, buildInit) {
                if(buildInit.project_id === project.id) {
                    var run = {
                        previous : runs[0] || null,
                        buildInit : buildInit,
                        id : buildInit.build_id,
                        commit_id : buildInit.commit_id,
                        started : moment(new Date(buildInit.timestamp * 1000)).format('LLLL'),
                        finished : false,
                        modules : '',
                        tests : ''
                    };
                    runsEl.prepend(t.logRun.render(run, t));
                    attachClickHandler(w.el('run-' + run.id)[0]);
                    runs.unshift(run);
                }
            }));
            page.beforego(function(from, to) {
                v.each(offs, function(off) {
                    off();
                });
            });
            var runLag = null;

            runs.reverse();
            v.each(runs, function(run) {
                run.origTime = run.time;
                run.time += ' ms';
                if(runLag === null) {
                    run.timeDelta = null;
                } else {
                    run.timeDelta = (run.origTime - runLag.origTime) + ' ms';
                }
                runLag = run;
            });
            runs.reverse();

            v.each(runs, function(run) {
                run.started = moment(new Date(run.started * 1000)).format('LLLL');
            });
            page.body.html(t.log.render({
                runs : runs,
                project : project
            }, t));
            var runsEl = bonzo(qwery('#runs'));
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
