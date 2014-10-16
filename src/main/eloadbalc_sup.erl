-module(eloadbalc_sup).

-behaviour(supervisor).

%% API
-export([start_link/1]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link(Conf) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, Conf).

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Takes Configuration of all nodes to monitor as a param.
%% Example:
%% {
%%  cpu,
%%  [{node1@example.com, 2000, 70},
%%  {node2@example.com, realtime, 50}]
%% }
%%
%% @end
%%--------------------------------------------------------------------
init(Conf) ->
  CollectorWorker = ?CHILD(eb_logic_worker, worker, [Conf]),
  {ok, {{one_for_one, 5, 10}, [CollectorWorker]}}.