### Erlang load balancer
#### Use cases
In case you have tasks of different heaviness, do not know your load limits and spawn as many threads, as possible - use it.
In any other situations - use poolboy, jobs, rabbitmq, pool or others.

#### Worker Configuration
There is no need to configure worker for getting statistics. Just sure, that os_mon application is started and eloadbalc 
is added as a rebar dep.

#### Balancer Configuration
Add eloadbalc as a rebar dep. Balancer system will use logic selection code and storing system metrics, while worker 
server will just execute code for getting metrics.  
Sample configuration:

    {
        Metric,
        [{Node, ConnectTime, UpdateTime, MaxValue}]
    }
Where Metric is atom `cpu`, `ram` or `counter`.  
`cpu` means that logic will collect cpu load percentage from all of your worker nodes.  
`ram` will collect free memory percentage.  
`counter` will collect statistics of run queue.  
`Node` is your node name with address, as an atom, f.e. `eloadbalc@127.0.0.1`.  
`ConnectTime` is a time for your balancer node to connect to worker. When node is down and error `{badrpc, nodedown}` is got
- this time is used against `UpdateTime`. __Important!__ Do not set this time too little, as often rpc calls can prevent your
 worker node from starting.  
`UpdateTime` is an atom `realtime` or integer value in milliseconds, means update frequency of statistics. Realtime requests 
will ask node on every `get_less_loaded` node request. They are more direct, but can produce load themselves.  
`MaxValue` is an integer value of maximum load. If current load exceeds this value - node will be turned off - and won't 
act in `get_less_loaded` calls.  
If you want to add your nodes after configuring balancer - use `eloadbalc:add_node/3`. It takes these parameters: 
`Node`, `MaxValue`, `UpdateTime`.

#### Usage
To connect eloadbalc to your app - add `eloadbalc_sup` to your supervision tree, and pass the configuration to it. It 
will start one server per your balancer system node. Than you can use `eloadbalc:get_less_loaded/0` to obtain less loaded
 node.
 
#### Troubleshooting 
If `eb_logic_worker` can't connect to remote node for statistics collection and you get badrpc error - first chech if rpc
protocol is allowed in your network firewall rules and two nodes have the same secret.  
If nodes can connect to each other, but you can't call eb_collector - check if it's code is loaded in the system. Simply
call `eb_collector:collect...` when your application start for loading the code.