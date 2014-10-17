%%%-------------------------------------------------------------------
%%% @author tihon
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Окт. 2014 1:29
%%%-------------------------------------------------------------------
-module(eb_logic_worker).
-author("tihon").

-behaviour(gen_server).

%% API
-export([start_link/1, get_all_data/0, add_node/1]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).
-define(ETS, nodes_load).

-record(state, {strategy :: atom()}).

%%%===================================================================
%%% API
%%%===================================================================
get_all_data() ->
  ets:foldl(fun check_data/2, [], ?ETS).

-spec add_node({Node :: atom(), Strgategy :: atom(), Max :: integer(), Time :: integer() | realtime}) -> ok.
add_node(Node) ->
  gen_server:call(?MODULE, {add, Node}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link(Params :: list()) ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link(Params) ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, Params, []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
%TODO dynamic nodes adding and deleting, changing timers and strategy
%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Params :: list()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init({Strategy, NodeList}) when Strategy == ram; Strategy == cpu; Strategy == counter ->
  ets:new(?ETS, [named_table, protected, {read_concurrency, true}]),
  set_up_monitoring(NodeList, Strategy),
  {ok, #state{strategy = Strategy}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call({add, {Node, Max, Time}}, _From, State = #state{strategy = Strategy}) ->
  set_up_node({Node, Time, Max}, Strategy),
  {reply, ok, State};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_info({update, Name, Time}, State) -> %update node information
  {Name, _, Max, Strategy} = ets:lookup(?ETS, Name),
  Data = eb_logic:fetch_node_data(Name, Strategy),
  check_max(Name, Data, Max, Strategy),
  timer:send_after(Time, {update, Name, Time}),
  {noreply, State};
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% @private
set_up_monitoring([], _) -> ok;
set_up_monitoring(NodeList, Strategy) when is_list(NodeList) ->
  lists:foreach(fun(Node) -> set_up_node(Node, Strategy) end, NodeList).

%% @private
set_up_node({Name, realtime, Max}, Strategy) when is_atom(Name) ->
  ets:insert(?ETS, {Name, realtime, Max, Strategy});
set_up_node({Name, Time, Max}, Strategy) when is_atom(Name) ->
  timer:send_after(Time, {update, Name, Time}),
  Data = eb_logic:fetch_node_data(Name, Strategy),
  ets:insert(?ETS, {Name, Data, Max, Strategy}).

%% @private
check_max(Node, Max, Current, Strategy) when Current > Max -> ets:insert(?ETS, {Node, off, Max, Strategy});
check_max(Node, Max, Current, Strategy) -> ets:insert(?ETS, {Node, Current, Max, Strategy}).

%% @private
check_data({Node, realtime, Max, Strategy}, {Ready, RT}) -> {Ready, [{Node, Max, Strategy} | RT]};
check_data({_, off, _, _}, Acc) -> Acc;
check_data({Node, Data, _, _}, {Ready, RT}) -> {[{Node, Data} | Ready], RT}.