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

defmodule LavaPotion.Struct.Player do
  alias LavaPotion.Struct.Node
  defstruct [:node, :guild_id, :session_id, :token, :endpoint, :track, :position, :volume, :is_real, :paused]

  def play(player = %__MODULE__{node: %Node{address: address}}, track) when is_binary(track) do
    info = LavaPotion.Api.decode_track(track)
    WebSockex.cast(Node.pid(address), {:play, player, {track, info}})
  end
  def play(player = %__MODULE__{node: %Node{address: address}}, %{"track" => track, "info" => info}) do
    WebSockex.cast(Node.pid(address), {:play, player, {track, info}})
  end

  def volume(player = %__MODULE__{node: %Node{address: address}}, volume) when is_number(volume) and volume >= 0 and volume <= 1000 do
    WebSockex.cast(Node.pid(address), {:volume, player, volume})
  end

  def seek(player = %__MODULE__{node: %Node{address: address}}, position) when is_number(position) and position >= 0 do
    WebSockex.cast(Node.pid(address), {:seek, player, position})
  end

  def pause(player = %__MODULE__{node: %Node{address: address}}), do: WebSockex.cast(Node.pid(address), {:pause, player, true})
  def resume(player = %__MODULE__{node: %Node{address: address}}), do: WebSockex.cast(Node.pid(address), {:pause, player, false})
  def destroy(player = %__MODULE__{node: %Node{address: address}}), do: WebSockex.cast(Node.pid(address), {:destroy, player})
  def stop(player = %__MODULE__{node: %Node{address: address}}), do: WebSockex.cast(Node.pid(address), {:stop, player})

  def set_node(player = %__MODULE__{node: %Node{address: address}, is_real: true}, node = %Node{}) do
    WebSockex.cast(Node.pid(address), {:update_node, player, node})
  end
end