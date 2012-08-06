REBAR=./rebar

.PHONY: deps distclean test

default: all

all: deps compile

clean:
	$(REBAR) clean
deps:
	$(REBAR) get-deps

compile:
	$(REBAR) compile

distclean:
	$(REBAR) delete-deps

test:
	$(REBAR) skip_deps=true eunit

test_%:
	$(REBAR) skip_deps=true verbose=1 suites=$* eunit

nodeps:
	$(REBAR) compile skip_deps=true

start-clean: clean all
	./init.sh
	./start.sh
