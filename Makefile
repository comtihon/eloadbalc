REBAR = `which rebar`

# ERLC_OPTS = +debug_info

all: deps compile

clean:
	@( $(REBAR) clean )

compile:
	@( $(REBAR) compile )

deps:
	@( $(REBAR) get-deps )

rel: compile
	@( $(REBAR) generate )
	
install: rel
	cp -r rel release

tests: compile
	rebar ct skip_deps=true

.PHONY: all rel deps compile clean ctags tests