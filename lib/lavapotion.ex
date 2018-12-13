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

defmodule LavaPotion do
  use Application
  use Supervisor

  alias LavaPotion.Stage

  def start(_type, _arg) do
    children = [
      supervisor(Stage, [])
    ]
    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]
    Supervisor.start_link(children, options)
  end

  defmacro __using__(_opts) do
    quote do
      alias LavaPotion.Struct.{Client, Node, Player}
      alias LavaPotion.Api

      require Logger

      def start_link() do
        Api.start()
        LavaPotion.Stage.Consumer.start_link(__MODULE__)
      end

      def handle_track_event(event, state) do
        Logger.warn "Unhandled Event: #{inspect event}"
        {:ok, state}
      end

      defoverridable [handle_track_event: 2]
    end
  end
end