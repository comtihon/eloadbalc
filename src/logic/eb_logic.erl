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
-export([fetch_node_data/2, get_less_loaded/0]).

%% get less loaded node
get_less_loaded() ->
  {Ready, Realtime} = eb_logic_worker:get_all_data(),
  RTData = get_realtime_data(Realtime),
  All = lists:append([Ready, RTData]),
  hd(lists:sort(fun sort_results/2, All)).

%% Fetch statistics data from a remote node
-spec fetch_node_data(Node :: atom(), Strategy :: cpu | ram | counter) -> Data :: integer().
fetch_node_data(Node, cpu) -> rpc:call(Node, eb_collector, collect_cpu_usage, []);
fetch_node_data(Node, ram) -> rpc:call(Node, eb_collector, collect_ram_usage, []);
fetch_node_data(Node, counter) -> rpc:call(Node, eb_collector, collect_run_queue, []).

%% @private
sort_results({_, A}, {_, B}) when A =< B -> true;
sort_results(_, _) -> false.

%% @private
get_realtime_data(Realtime) ->
  lists:foldl(
    fun({Node, Max, Strategy}, Collected) ->
      case fetch_node_data(Node, Strategy) of
        Data when Data > Max -> Collected;
        Data -> [{Node, Data} | Collected]
      end
    end, [], Realtime).