Perforator CI
=============

Perforator CI is a continious integration server used for performance
regression testing.

It is used together with the Perforator performance unit testing tool,
which is can be found here: https://github.com/yfyf/perforator

Dependencies
----

* git
* tested only on Linux, sorry
* [npm](http://npmjs.org)

Quick tutorial
-----

Start the Perforator CI server:

```
   git clone https://github.com/brb/perforator-ci
   cd perforator-ci/
   make start-clean
```

Perforator CI should be running on http://localhost:8080/

We need add a project which does some performance unit testing.

[The Eight Myths of Erlang
Performance](http://www.erlang.org/doc/efficiency_guide/myths.html) are pretty
interesting to investigate and we have prepared a special repo for that at
https://github.com/yfyf/8-myths-of-erlang.git
Add it as a project and keep the default build steps. (Warning: repo should be
accessible, otherwise CI will crash.)

Do a few builds and click around, you should experience some fabulous
statistics.

Current problems
-----

* some of the statistics are sloppy, so don't call us for a refund, we know,
  we're working on it. The test duration measureument is pretty tight though.
* stuff is very fragile, be gentle.
