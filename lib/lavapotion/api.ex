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

defmodule LavaPotion.Api do
  import WebSockex

  def start_http(), do: HTTPoison.start

  def initialize(pid, guild_id, session_id, token, endpoint) when is_pid(pid) and is_binary(guild_id) and is_binary(token) and is_binary(endpoint) do
    cast(pid, {:voice_update, guild_id, session_id, token, endpoint})
  end

  def play(pid, guild_id, track) when is_pid(pid) and is_binary(guild_id) and is_binary(track) do
    cast(pid, {:play, guild_id, track})
  end
  def play(pid, guild_id, %{"track" => track}), do: play(pid, guild_id, track)

  def volume(pid, guild_id, volume) when is_pid(pid) and is_binary(guild_id) and is_number(volume) and volume >= 0 and volume <= 1000 do
    cast(pid, {:volume, guild_id, volume})
  end

  def seek(pid, guild_id, position) when is_pid(pid) and is_binary(guild_id) and is_number(position) do
    cast(pid, {:seek, guild_id, position})
  end

  def pause(pid, guild_id) when is_pid(pid) and is_binary(guild_id), do: cast(pid, {:pause, guild_id, true})
  def resume(pid, guild_id) when is_pid(pid) and is_binary(guild_id), do: cast(pid, {:pause, guild_id, false})
  def stop(pid, guild_id) when is_pid(pid) and is_binary(guild_id), do: cast(pid, {:stop, guild_id})
  def destroy(pid, guild_id) when is_pid(pid) and is_binary(guild_id), do: cast(pid, {:destroy, guild_id})

  def load_tracks(node, identifier) when not is_nil(node) and is_binary(identifier) do
    alias LavaPotion.Struct.LoadTrackResponse
    body = HTTPoison.get!("http://#{node.address}:#{node.port}/loadtracks?identifier=#{URI.encode(identifier)}", ["Authorization": node.password]).body
    |> Poison.decode!(as: %LoadTrackResponse{})
  end
end