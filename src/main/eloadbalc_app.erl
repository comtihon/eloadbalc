-module(eloadbalc_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
  {ok, Conf} = application:get_env(conf),
  eloadbalc_sup:start_link(Conf).

stop(_State) ->
  ok.
