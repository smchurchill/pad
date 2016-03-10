defmodule Event do
  require Record
  Record.defrecord :state, [:server, :name, :to_go]
  
  def start(event_name, delay) do
    spawn(Event, :init, [self, event_name, delay])
  end
  
  def start_link(event_name, delay) do
    spawn_link(Event, :init, [self, event_name, delay])
  end
  
  def init(server, event_name, datetime) do
    loop( state( server: server,
                 name: event_name,
                 to_go: time_to_go(datetime)))
  end

  def cancel(to_cancel) do
    ref = Process.monitor(to_cancel)
    send to_cancel, {self, ref, :cancel}
    receive do
      {ref, :ok} ->
        Process.demonitor(ref, [:flush])
        :ok
      {'DOWN', _ref, :process, _to_cancel, _reason} ->
        :ok
    end 
  end
  

  def loop( _s = state( server: server_in,
                       name: name_in,
                       to_go: [t | next])) do
    receive do
      {server, ref, :cancel} -> send server, {ref, :ok}
    after t*1000 ->
      cond do
        next === [] ->
          send server_in, {:done, name_in}
        next !== [] ->
          loop( state( server: server_in,
                       name: name_in,
                       to_go: next))
      end
    end
  end
  
  def time_to_go(timeout={{_,_,_},{_,_,_}}) do
    now = :calendar.local_time()
    togo =
      :calendar.datetime_to_gregorian_seconds(timeout) -
      :calendar.datetime_to_gregorian_seconds(now)
    secs = cond do
      togo > 0 -> togo
      togo <= 0 -> 0
    end
    normalize(secs)
  end
  
  def normalize(n) do
    limit = 7*24*60*60
    [rem(n, limit) | List.duplicate(limit, div(n, limit))]
  end

end


