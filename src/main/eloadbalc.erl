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
-export([get_less_loaded/0, add_node/4, get_less_loaded_random/0]).

%% get less loaded node
-spec get_less_loaded() -> {Node :: atom(), Load :: integer()} | [].
get_less_loaded() ->
  case eb_logic:get_all_sorted() of
    [] -> [];
    List -> hd(List)
  end.

%% same as get loaded, but if there are several nodes with same load - take random (same with 5% delta)
-spec get_less_loaded_random() -> {Node :: atom(), Load :: integer()} | [].
get_less_loaded_random() ->
  case eb_logic:get_all_sorted() of
    [] -> [];
    All when length(All) == 1 ->
      hd(All);
    All ->
      Min = hd(All),
      Filtered = (catch lists:foldr(
        fun(Current, Acc) when Min + 5 > Current -> %Current should not be more, than min element + delta
          [Current | Acc];
          (_, Acc) -> throw(Acc)  %stom processing, others are bigger
        end,
        [], All)),
      lists:nth(random:uniform(length(Filtered)), Filtered)
  end.

%% dynamic adding a node
-spec add_node(atom(), integer(), integer(), integer() | atom()) -> ok.
add_node(Node, MaxValue, StartTime, UpdateTime) ->
  eb_logic_worker:add_node({Node, StartTime, UpdateTime, MaxValue}).