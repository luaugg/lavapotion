# Copyright 2018 Sam Pritchard
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule LavaPotion.Stage.Consumer do
  use GenStage

  alias LavaPotion.Stage.Middle

  require Logger

  def start_link(handler) do
    GenStage.start_link(__MODULE__, %{handler: handler, public: []}, name: __MODULE__)
  end

  def init(state), do: {:consumer, state, subscribe_to: [Middle]}

  def handle_events(events, _from, state) do
    new = handle(events, state)
    {:noreply, [], new}
  end

  def handle([], state), do: state
  def handle([args = [type, _args] | events], map = %{handler: handler}) do
    handler
    |> apply(:handle_track_event, args)
    |> case do
         {:ok, state} ->
          Logger.debug "Handled Event: #{inspect type}"
          handle(events, %{map | public: state})
         term ->
          raise "expected {:ok, state}, got #{inspect term}"
       end
  end
  def handle(_data, map) do
    Logger.warn "Unhandled Event: #{inspect map}"
  end
end