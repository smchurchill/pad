defmodule Server do
  require Record
  Record.defrecord :state, [:events, :clients]
  Record.defrecord :event, [:name, :description, :id, timeout: {{3000,1,1},{0,0,0}}]

  def start do
    Process.register(id = spawn(__MODULE__, :init, []), __MODULE__)
    id
  end

  def start_link do
    Process.register(id = spawn_link(__MODULE__, :init, []), __MODULE__)
    id
  end

  def terminate do
    send __MODULE__, :shutdown
  end

  def subscribe(client) do
    ref = Process.monitor(client)
    send __MODULE__, {self, ref, {:subscribe, client}}
    receive do
      {^ref, :ok} ->
        {:ok, ref}
      {'DOWN', _ref, :process, _pid, reason} ->
        {:error, reason}
    after 5000 ->
      {:error, :timeout}
    end   
  end

  def add_event(name, description, timeout) do
    ref = make_ref
    send __MODULE__, {self, ref, {:add, name, description, timeout}}
    receive do
      {^ref, msg} ->
        msg
    after 5000 ->
      {:error, :timeout}
    end
  end

  def cancel(name) do
    ref = make_ref
    send __MODULE__, {self, ref, {:cancel, name}}
    receive do
      {^ref, :ok} ->
        :ok
    after 5000 ->
      {:error, :timeout}
    end
  end

  def listen(delay) do
    receive do
      m = {:done, _name, _description} ->
        [m | listen(0)]
    after 1000*delay ->
        []
    end
  end

  


  def init do
    loop( state( events: :orddict.new, 
                 clients: :orddict.new))
  end

  def loop( s = state(events: old_events,
                      clients: old_clients) ) do
    receive do
      {from, msg_ref, {:subscribe, client}} ->
        client_ref = Process.monitor(client)
        new_clients = :orddict.store(client_ref,
                                    client,
                                    state(s, :clients))
        send from, {msg_ref, :ok}
        loop(
          state(
            events: old_events,
            clients: new_clients) )        
      
      {from, msg_ref, {:add, name, descr, timeout}} ->
        case valid_datetime(timeout) do
          true ->
            event_pid = Event.start_link(name, timeout)
            new_events = :orddict.store(
              name,
              event(
                name: name,
                description: descr,
                id: event_pid),
              old_events)
            send from, {msg_ref, :ok}
            loop(
              state(
                events: new_events,
                clients: old_clients) )
          false ->
            send from, {msg_ref, {:error, :bad_timeout}}
            loop(s)
        end

      {from, msg_ref, {:cancel, name}} ->
        new_events = case :orddict.find(name, old_events) do
          {:ok, e} ->
            Event.cancel(event(e, :id))
            :orddict.erase(name, old_events)
          :error ->
            old_events
          end
        send from, {msg_ref, :ok}
        loop(
          state(
            events: new_events,
            clients: old_clients) )            
      
      {:done, name} ->
        case :orddict.find(name, old_events) do
          {:ok, e} ->
            send_to_clients(
              {  :done,
                 event(e, :name),
                 event(e, :description)},
              old_clients)
            new_events = :orddict.erase(name, old_events)
            loop(
              state(
                events: new_events,
                clients: old_clients) )
          :error ->
            loop(s) 
        end 

      :shutdown ->
        exit(:shutdown)
        
      {'DOWN', client_ref, :process, _id, _reason} ->
        new_clients =
          case :orddict.find(client_ref, old_clients) do
            {:ok, _} ->
              :orddict.erase(client_ref, old_clients)
            :error ->
              old_clients
          end
        loop(
          state(
            events: old_events,
            clients: new_clients) )
            
      
      :code_change ->
        __MODULE__.loop(s)
      
      _unknown ->
        :io.format("Unknown message: ~p~n", [Unknown])
        loop(s)
    end
  end

  def send_to_clients(msg, client_dict) do
    :orddict.map(
      fn(_ref, id) ->
        send id, msg
      end,
      client_dict)
  end

  def valid_datetime({date, time}) do
    try do
      :calendar.valid_date(date) and valid_time(time)
    rescue
      RuntimeError ->
        false
    end
  end

  def valid_datetime(_) do
      false
  end

  def valid_time({h,m,s}) do
    valid_time(h,m,s)
  end

  def valid_time(h,m,s) when
      h >= 0 and h < 24 and
      m >= 0 and m < 60 and
      s >= 0 and s < 60 do
        true
  end
  
  def valid_time(_,_,_) do
    false
  end

end
