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

defmodule LavaPotion.Struct.Node do
  use WebSockex
  import Poison
  alias LavaPotion.Struct.{VoiceUpdate, Play, Pause, Stop, Destroy, Volume, Seek, Player, Stats}
  require Logger

  defstruct [:password, :port, :address, :client]

  @ets_lookup :lavapotion_ets_table
  @stats_max_int :math.pow(2, 31) - 1
  @stats_no_stats @stats_max_int - 1

  @typedoc """

  """
  @type t :: %__MODULE__{}

  def new(opts) do
    client = opts[:client]
    if client == nil do
      raise "client is nil"
    end

    address = opts[:address]
    if !is_binary(address) do
      raise "address is not a binary string"
    end

    port = opts[:port] || client.default_port
    if !is_number(port) do
      raise "port is not a number"
    end

    password = opts[:password] || client.default_password
    if !is_binary(password) do
      raise "password is not a binary string"
    end

    %__MODULE__{client: client, password: password, address: address, port: port}
  end

  def start_link(mod) do
    result = {:ok, pid} = WebSockex.start_link("ws://#{mod.address}:#{mod.port}", __MODULE__, %{},
      extra_headers: ["User-Id": mod.client.user_id, "Authorization": mod.password, "Num-Shards": mod.client.shard_count],
      handle_initial_conn_failure: true, async: true)
    if :ets.whereis(@ets_lookup) === :undefined, do: :ets.new(@ets_lookup, [:set, :public, :named_table])
    :ets.insert(@ets_lookup, {mod.address, %{node: mod, stats: nil, players: %{}, pid: pid}})
    result
  end

  def handle_connect(conn, _state) do
    Logger.info "Connected to #{conn.host}!"
    {:ok, conn}
  end

  def handle_disconnect(%{reason: {:local, _}, conn: conn}, state) do
    Logger.info "Client disconnected from #{conn.host}!"
    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, _, _}, conn: conn}, state) do
    Logger.info "Client disconnected from #{conn.host}!"
    {:ok, state}
  end

  def handle_disconnect(%{reason: {:remote, code, message}, attempt_number: attempt_number, conn: conn}, state) when attempt_number < 5 do
    # todo change to info if code = 1001 or 1000
    Logger.warn "Disconnected from #{conn.host} by server with code: #{code} and message: #{message}! Reconnecting..."
    {:reconnect, state}
  end

  def handle_disconnect(%{reason: {:remote, code, message}, conn: conn}, state) do
    # todo change to info if code == 1001 or 1000
    Logger.warn "Disconnected from #{conn.host} by server with code: #{code} and message: #{message}!"
    {:ok, state}
  end

  def handle_disconnect(%{reason: {:remote, :closed}, conn: conn}, state) do
    Logger.warn "Abruptly disconnected from #{conn.host} by server!"
    {:ok, state}
  end

  defp best_node_iter(current = {_node, record}, nodes) do
    if Enum.empty?(nodes) do
      current
    else
      node = List.first(nodes)
      nodes = List.delete_at(nodes, 0)
      result = case node do
        {_host, %{node: node = %__MODULE__{}, stats: nil}} -> {node, @stats_no_stats}
        {_host, %{node: node = %__MODULE__{}, stats: %Stats{playingPlayers: playing_players, cpu: %{systemLoad: system_load}, frameStats: %{nulled: nulled, deficit: deficit}}}} ->
          {node, playing_players +
            (:math.pow(1.05, 100 * system_load) * 10 - 10) +
            (:math.pow(1.03, 500 * (deficit / 3000)) * 600 - 600) +
            (:math.pow(10.3, 500 + (nulled / 3000)) * 300 - 300) * 2}
        {_host, %{node: node = %__MODULE__{}, stats: %Stats{playingPlayers: playing_players, cpu: %{systemLoad: system_load}, frameStats: nil}}} ->
          {node, playing_players + (:math.pow(1.05, 100 * system_load) * 10 - 10)}
        {_host, %{node: node = %__MODULE__{}}} -> {node, @stats_no_stats}
        _ -> {:error, :malformed_data}
      end

      if result !== {:error, :malformed_data} && elem(result, 1) < record do
        best_node_iter(result, nodes)
      else
        best_node_iter(current, nodes)
      end
    end
  end
  def best_node() do
    list = :ets.tab2list(@ets_lookup) # woefully inefficient, might replace with select later?
    case best_node_iter({nil, @stats_max_int}, list) do
      {nil, _} -> {:error, :no_available_node}
      {node = %__MODULE__{}, _} -> {:ok, node}
      _ -> {:error, :malformed_return_value}
    end
  end

  def pid(%__MODULE__{address: address}), do: pid(address)
  def pid(address) when is_binary(address) do
    [{_, %{pid: pid}}] = :ets.lookup(@ets_lookup, address)
    pid
  end

  def node(address) when is_binary(address) do
    [{_, %{node: node = %__MODULE__{}}}] = :ets.lookup(@ets_lookup, address)
    node
  end

  def players(%__MODULE__{address: address}), do: players(address)
  def players(address) when is_binary(address) do
    [{_, %{players: players}}] = :ets.lookup(@ets_lookup, address)
    players
  end

  def player(%__MODULE__{address: address}, guild_id), do: player(address, guild_id)
  def player(address, guild_id) when is_binary(address) and is_binary(guild_id) do
    [{_, %{players: players}}] = :ets.lookup(@ets_lookup, address)
    players[guild_id]
  end

  def handle_cast({:voice_update, player = %Player{guild_id: guild_id, token: token, endpoint: endpoint, session_id: session_id, is_real: false}}, state) do
    event = %{guild_id: guild_id, token: token, endpoint: endpoint}
    update = encode!(%VoiceUpdate{guildId: guild_id, sessionId: session_id, event: event})
    [{_, map = %{node: node, players: players}}] = :ets.lookup(@ets_lookup, state.host)
    players = Map.put(players, guild_id, %Player{player | node: node, is_real: true})

    :ets.insert(@ets_lookup, {state.host, %{map | players: players}})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:play, player = %Player{guild_id: guild_id, is_real: true}, data = {track, _info}}, state) do
    update = encode!(%Play{guildId: guild_id, track: track})
    [{_, map = %{players: players}}] = :ets.lookup(@ets_lookup, state.host)
    players = Map.put(players, guild_id, %Player{player | track: data})

    :ets.insert(@ets_lookup, {state.host, %{map | players: players}})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:volume, player = %Player{guild_id: guild_id, is_real: true}, volume}, state) do
    update = encode!(%Volume{guildId: guild_id, volume: volume})
    [{_, map = %{players: players}}] = :ets.lookup(@ets_lookup, state.host)
    players = Map.put(players, guild_id, %Player{player | volume: volume})

    :ets.insert(@ets_lookup, {state.host, %{map | players: players}})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:seek, %Player{guild_id: guild_id, is_real: true, track: {_data, %{"length" => length}}}, position}, state) do
    if position > length do
      Logger.warn("guild id: #{guild_id} | specified position (#{inspect position}) is larger than the length of the track (#{inspect length})")
      {:ok, state}
    else
      update = encode!(%Seek{guildId: guild_id, position: position})
      # updated upon player update
      {:reply, {:text, update}, state}
    end
  end

  def handle_cast({:pause, player = %Player{guild_id: guild_id, is_real: true, paused: paused}, pause}, state) do
    if pause == paused do
      {:ok, state}
    else
      update = encode!(%Pause{guildId: guild_id, pause: pause})
      [{_, map = %{players: players}}] = :ets.lookup(@ets_lookup, state.host)
      players = Map.put(players, guild_id, %Player{player | paused: pause})

      :ets.insert(@ets_lookup, {state.host, %{map | players: players}})
      {:reply, {:text, update}, state}
    end
  end

  def handle_cast({:destroy, %Player{guild_id: guild_id, is_real: true}}, state) do
    update = encode!(%Destroy{guildId: guild_id})
    [{_, map = %{players: players}}] = :ets.lookup(@ets_lookup, state.host)
    players = Map.delete(players, guild_id)

    :ets.insert(@ets_lookup, {state.host, %{map | players: players}})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:stop, %Player{guild_id: guild_id, is_real: true, track: track}}, state) do
    if track == nil do
      Logger.warn "player for guild id #{guild_id} already isn't playing anything."
      {:ok, state}
    else
      update = encode!(%Stop{guildId: guild_id})
      # updated upon TrackEndEvent
      {:reply, {:text, update}, state}
    end
  end

  def handle_cast({:update_node, player = %Player{guild_id: guild_id, is_real: true, node: old_node = %__MODULE__{}}, new_node = %__MODULE__{}}, state) when new_node !== old_node do
    Player.destroy(player)
    [{_, map = %{players: players}}] = :ets.lookup(@ets_lookup, state.host)
    player = %Player{player | node: new_node, is_real: false}
    players = Map.put(players, guild_id, player)

    Player.initialize(player)
    :ets.insert(@ets_lookup, {state.host, %{map | players: players}})
    {:ok, state}
  end

  def handle_cast({:update_node, %Player{guild_id: guild_id, is_real: true, node: old_node = %__MODULE__{}}, new_node = %__MODULE__{}}, state) when new_node === old_node do
    Logger.warn "player for guild id #{guild_id} attempt to update node to current node?"
    {:ok, state}
  end

  def terminate(_reason, state) do
    Logger.warn "Connection to #{state.host} terminated!"
    exit(:normal)
  end

  def handle_frame({:text, message}, state) do
    data = %{"op" => op} = Poison.decode!(message)
    case op do
      "stats" ->
        stats = Poison.decode!(message, as: %Stats{})
        [{_, map = %{}}] = :ets.lookup(@ets_lookup, state.host)
        :ets.insert(@ets_lookup, {state.host, %{map | stats: stats}})

      "playerUpdate" ->
        %{"guildId" => guild_id, "state" => %{"position" => position, "time" => time}} = data
        [{_, map = %{players: players = %{^guild_id => player = %Player{}}}}] = :ets.lookup(@ets_lookup, state.host)
        players = Map.put(players, guild_id, %Player{player | raw_position: position, raw_timestamp: time})
        :ets.insert(@ets_lookup, {state.host, %{map | players: players}})

      "event" ->
        # TODO: actual handling/event publishing
        %{"guildId" => guild_id, "type" => type} = data
        case type do
          "TrackEndEvent" ->
            [{_, map = %{players: players = %{^guild_id => player = %Player{}}}}] = :ets.lookup(@ets_lookup, state.host)
            players = Map.put(players, guild_id, %Player{player | track: nil})
            :ets.insert(@ets_lookup, {state.host, %{map | players: players}})

          "TrackExceptionEvent" ->
            Logger.error "error in player for guild id: #{guild_id} | message: #{data["error"]}"

          "TrackStuckEvent" ->
            Logger.warn "track stuck for player/guild id: #{guild_id}"

          "WebSocketClosedEvent" ->
            Logger.warn "audio websocket connection to discord closed for guild id: #{guild_id}, code: #{data["code"]}, reason: #{data["reason"]}"
        end

      _ ->
        Logger.warn "Unhandled Event: #{op} | Data: #{message}"
    end
    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}
end