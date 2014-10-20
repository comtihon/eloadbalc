%%%-------------------------------------------------------------------
%%% @author tihon
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Окт. 2014 2:31
%%%-------------------------------------------------------------------
-module(eloadbalc).
-author("tihon").

%% API
-export([get_less_loaded/0, add_node/4]).

%% get less loaded node
-spec get_less_loaded() -> {Node :: atom(), Load :: integer()} | [].
get_less_loaded() ->
  {Ready, Realtime} = eb_logic_worker:get_all_data(),
  RTData = eb_logic:get_realtime_data(Realtime),
  All = lists:append([Ready, RTData]),
  case lists:sort(fun eb_logic:sort_results/2, All) of
    [] -> [];
    List -> hd(List)
  end.

%% dynamic adding a node
-spec add_node(atom(), integer(), integer(), integer() | atom()) -> ok.
add_node(Node, MaxValue, StartTime, UpdateTime) ->
  eb_logic_worker:add_node({Node, StartTime, UpdateTime, MaxValue}).

