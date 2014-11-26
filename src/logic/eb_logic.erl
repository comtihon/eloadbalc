%%%-------------------------------------------------------------------
%%% @author tihon
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Окт. 2014 2:40
%%%-------------------------------------------------------------------
-module(eb_logic).
-author("tihon").

%% API
-export([fetch_node_data/2, get_all_sorted/0]).

%% Fetch statistics data from a remote node
-spec fetch_node_data(Node :: atom(), Strategy :: cpu | ram | counter) -> Data :: integer().
fetch_node_data(Node, cpu) -> process_result(rpc:call(Node, eb_collector, collect_cpu_usage, []));
fetch_node_data(Node, ram) -> process_result(rpc:call(Node, eb_collector, collect_ram_usage, []));
fetch_node_data(Node, counter) -> process_result(rpc:call(Node, eb_collector, collect_run_queue, [])).

%% Get all nodes, sorted by load
get_all_sorted() ->
  {Ready, Realtime} = eb_logic_worker:get_all_data(),
  RTData = get_realtime_data(Realtime),
  All = lists:append([Ready, RTData]),
  lists:sort(fun sort_results/2, All).


%% @private
sort_results({_, A}, {_, B}) when A =< B -> true;
sort_results(_, _) -> false.

%% @private
get_realtime_data(Realtime) ->
  lists:foldl(
    fun({Node, Max, Strategy}, Collected) ->
      case fetch_node_data(Node, Strategy) of
        Data when Data > Max; Data == off ->
          eb_logic_worker:restart_node(Node), %ask collector to restart node
          Collected;
        Data -> [{Node, Data} | Collected]
      end
    end, [], Realtime).

%% @private
process_result({badrpc, _}) -> off;
process_result(Data) -> Data.