defmodule Event do

  require Record
  Record.defrecord :state, [:server, :name, :to_go]

  def loop(s) do
    receive do
      {server, ref, :cancel} -> send server, {ref, :ok}
    after state(s, :to_go)*1000 ->
      send state(s, :server), {:done, state(s, :name)}
    end
  end

end

