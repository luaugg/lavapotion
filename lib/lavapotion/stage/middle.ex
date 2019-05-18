defmodule LavaPotion.Stage.Middle do
  use GenStage

  alias LavaPotion.Stage.Producer

  require Logger

  def start_link(), do: GenStage.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(state), do: {:producer_consumer, state, subscribe_to: [Producer]}

  def handle_events(events, _from, state) do
    events = events
    |> Enum.map(
          fn data = %{"op" => opcode} ->
            handle(opcode, data)
          end
       )
    |> Enum.filter(&(&1 !== :ignore))
    {:noreply, events, state}
  end

  def handle(_op, data), do: data
end
