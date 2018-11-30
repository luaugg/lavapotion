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
  alias LavaPotion.Struct.{LoadTrackResponse, AudioTrack, Player, Node}

  def start(), do: HTTPoison.start

  def initialize(pid, guild_id, session_id, token, endpoint) when is_pid(pid) and is_binary(guild_id) and is_binary(session_id) and is_binary(token) and is_binary(endpoint) do
    WebSockex.cast(pid, {:voice_update, %Player{guild_id: guild_id, session_id: session_id, token: token, endpoint: endpoint, is_real: false}})
  end

  def initialize(pid, player = %Player{is_real: false}) when is_pid(pid) do
    WebSockex.cast(pid, {:voice_update, player})
  end

  def load_tracks(identifier) do
    load_tracks(Node.best_node(), identifier)
  end

  def load_tracks(%Node{address: address, port: port, password: password}, identifier) do
    load_tracks(address, port, password, identifier)
  end

  def load_tracks(address, port, password, identifier) when is_binary(address) and is_number(port) and is_binary(password) and is_binary(identifier) do
    HTTPoison.get!("http://#{address}:#{port}/loadtracks?identifier=#{URI.encode(identifier)}", ["Authorization": password]).body
    |> Poison.decode!(as: %LoadTrackResponse{})
  end

  def decode_track(track) do
    decode_track(Node.best_node(), track)
  end

  def decode_track(%Node{address: address, port: port, password: password}, track) do
    decode_track(address, port, password, track)
  end

  def decode_track(address, port, password, track) when is_binary(address) and is_number(port) and is_binary(password) and is_binary(track) do
    HTTPoison.get!("http://#{address}:#{port}/decodetrack?track=#{URI.encode(track)}", ["Authorization": password]).body
    |> Poison.decode!(as: %AudioTrack{})
  end
end