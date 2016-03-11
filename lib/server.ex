defmodule Server do
  require Record
  Record.defrecord :state, [:events, :clients]
  Record.defrecord :event, [:name, :description, :id, timeout: {{3000,1,1},{0,0,0}}]



  def init do
    loop( state( events: Orddict.new, 
                 clients: Orddict.new))
  end

  def loop( s = state(events: old_events,
                      clients: old_clients) ) do
    receive
      {from, msg_ref, {:subscribe, client}} ->
        client_ref = Process.monitor(client)
        new_clients = Orddict.store(client_ref,
                                    client,
                                    state(s, :clients)
        send from, {msg_ref, :ok}
        loop( state(events: old_events,
              clients: new_clients) )        
      
      {from, msg_ref, {:add, name, descr, timeout}} ->
      
      {from, msg_ref, {:cancel, name}} ->
      
      :shutdown ->
      
      {'DOWN', _ref, :process, _pid, _reason} ->
      
      :code_change ->
      
      unknown ->
        :io.format("Unknown message: ~p~n", [Unknown])
        loop(state)
  
  end

  def valid_datetime do
    
  end

end
