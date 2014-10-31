%%%-------------------------------------------------------------------
%%% @author tihon
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Окт. 2014 0:14
%%%-------------------------------------------------------------------
-module(eb_collector).
-author("tihon").

%% API
-export([collect_cpu_usage/0, collect_ram_usage/0, collect_run_queue/0]).

%% Get cpu persentage usage
-spec collect_cpu_usage() -> integer().
collect_cpu_usage() ->
  round(cpu_sup:util()).

%% Get ram persentage usage
-spec collect_ram_usage() -> integer().
collect_ram_usage() ->
  {All, _, _} = memsup:get_memory_data(),
  Info = memsup:get_system_memory_data(),
  Free = proplists:get_value(free_memory, Info),
  Buffered = proplists:get_value(buffered_memory, Info),
  Cached = proplists:get_value(cached_memory, Info),
 100 - round((100 / All) * (Free + Buffered + Cached)).

%% Get length of tasks run queue
-spec collect_run_queue() -> integer().
collect_run_queue() ->
  statistics(run_queue).