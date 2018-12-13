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

defmodule LavaPotion.Stage.Producer do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_state) do
    {:producer, {:queue.new(), 0}}
  end

  def notify(event) do
    GenStage.cast(__MODULE__, {:notify, event})
  end

  def handle_demand(new, {queue, demand}) do
    queue_events({demand + new, []}, queue)
  end

  def handle_cast({:notify, event}, {queue, demand}) do
    queue = :queue.in(event, queue)
    queue_events({demand, []}, queue)
  end

  defp queue_events({0, current}, queue) do
    {:noreply, Enum.reverse(current), {queue, 0}}
  end
  defp queue_events({demand, current}, queue) do
    case :queue.out(queue) do
      {{:value, val}, queue} ->
        queue_events({demand - 1, [val | current]}, queue)
      _ ->
        {:noreply, Enum.reverse(current), {queue, demand}}
    end
  end
end