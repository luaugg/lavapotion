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
  defstruct [:pid, :node, :guild_id, :session_id, :token, :endpoint, :track, :position, :volume, :is_real, :paused]

  def play(player, track) when not is_nil(player) and is_binary(track) do
    info = LavaPotion.Api.decode_track(player.node, track)
    WebSockex.cast(player.pid, {:play, player, {track, info}})
  end
  def play(player, %{"track" => track, "info" => info}), do: WebSockex.cast(player.pid, {:play, player, {track, info}})

  def volume(player, volume) when not is_nil(player) and is_number(volume) and volume >= 0 and volume <= 1000 do
    WebSockex.cast(player.pid, {:volume, player, volume})
  end

  def seek(player, position) when not is_nil(player) and is_number(position) and position >= 0 do
    WebSockex.cast(player.pid, {:seek, player, position})
  end

  def pause(player) when not is_nil(player), do: WebSockex.cast(player.pid, {:pause, player, true})
  def resume(player) when not is_nil(player), do: WebSockex.cast(player.pid, {:pause, player, false})
  def destroy(player) when not is_nil(player), do: WebSockex.cast(player.pid, {:destroy, player})
  def stop(player) when not is_nil(player), do: WebSockex.cast(player.pid, {:stop, player})

  def set_node(player, node) when not is_nil(player) and not is_nil(node) do
    WebSockex.cast(player.pid, {:update_node, player, node})
  end
end