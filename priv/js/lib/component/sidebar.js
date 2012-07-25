var w = require('../window');
var t = require('../templates');
var bean = require('bean');
var qwery = require('qwery');
var bonzo = require('bonzo');
var v = require('valentine');
var common = require('../common');

exports.init = function(page, cb) {
    var insertProject = function(projects, project) {
        for(var i = 0; i < projects.length; i += 1) {
            if(projects[i].id > project.id) {
                projects.splice(i, 0, project);
                return {
                    after : false,
                    project : projects[i + 1]
                };
            }
        }
        projects.push(project);
        return {
            after : projects.length === 1 ? null : true,
            project : projects[projects.length - 2]
        };
    };

    var replaceProject = function(projects, project) {
        for(var i = 0; i < projects.length; i += 1) {
            if(projects[i].id === project.id) {
                projects[i] = project;
                return;
            }
        }
    };

    page.req('projects', null, function(_, projects) {
        var updateSidebar = function() {
            v.each(projects, function(p) {
                if(page.projectId === p.id) {
                    p.opened = true;
                } else {
                    p.opened = false;
                }
            });
            w.el('sidebar').html(t.sidebar.render({
                projectId : page.projectId,
                projects : projects,
                workers : page.store.builders
            }, t));
            bean.add(w.el('build-now')[0], 'click', function(e) {
                common.notify('A new build has been started');
                page.req('build_now', page.projectId);
                e.preventDefault();
            });
        };
        bean.add(page, 'projectId', updateSidebar);
        updateSidebar();
        var addBuilderListener = function(builder) {
            var onUpdate = function() {
                w.el('builder-li-' + builder.name).replaceWith(t.worker.render(builder));
            };
            var onDelete = function() {
                bean.remove(builder, 'update', onUpdate);
                bean.remove(builder, 'delete', onDelete);
            };
            bean.add(builder, 'update', onUpdate);
            bean.add(builder, 'delete', onDelete);
        };
        bean.add(page.store.builders, 'endUpdate', function(changes) {
            bonzo(qwery('.app-worker')).remove();
            var html = '';
            v.each(page.store.builders, function(builder) {
                html += t.worker.render(builder);
            });
            v.each(changes.inserted, addBuilderListener);
            w.el('sidebar').append(html);
        });
        v.each(page.store.builders, addBuilderListener);
        bean.add(page, 'projectUpdated', function(project) {
            replaceProject(projects, project);
            if(project.id === page.projectId) {
                project.opened = true;
            }
            w.el('project-' + project.id).replaceWith(t.project.render(project));
        });
        bean.add(page, 'projectAdded', function(project) {
            if(project.id === page.projectId) {
                project.opened = true;
            }
            var position = insertProject(projects, project);
            var html = t.project.render(project);
            if(position.after === null) {
                w.el('projects-header').after(html);
            } else {
                if(position.after) {
                    w.el('project-' + position.project.id).after(html);
                } else {
                    w.el('project-' + position.project.id).before(html);
                }
            }
        });
    });
    cb(null);
};
