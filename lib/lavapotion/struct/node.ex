defmodule LavaPotion.Struct.Node do
  use WebSockex
  import Poison
  defstruct password: nil, port: nil, address: nil, stats: %{}, players: %{}, client: nil


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
    WebSockex.start_link("ws://#{mod.address}:#{mod.port}", __MODULE__, %{},
      extra_headers: ["User-Id": mod.client.user_id, "Authorization": mod.password, "Num-Shards": mod.client.shard_count],
      handle_initial_conn_failure: true)
  end

  def handle_connect(conn, state) do
    IO.puts "Connected to #{conn.host}!"
    {:ok, conn}
  end

  def handle_disconnect(params = %{reason: {:local, _}, conn: conn}, state) do
    IO.puts "Client disconnected from #{conn.host}!"
    {:ok, state}
  end

  def handle_disconnect(params = %{reason: {:local, _, _}, conn: conn}, state) do
    IO.puts "Client disconnected from #{conn.host}!"
    {:ok, state}
  end

  def handle_disconnect(params = %{reason: {:remote, code, message}, attempt_number: attempt_number, conn: conn}, state) when attempt_number < 5 do
    IO.puts "Disconnected from #{conn.host} by server with code: #{code} and message: #{message}! Reconnecting..."
    {:reconnect, state}
  end

  def handle_disconnect(params = %{reason: {:remote, code, message}, conn: conn}, state) do
    IO.puts "Disconnected from #{conn.host} by server with code: #{code} and message: #{message}!"
    {:ok, state}
  end

  def handle_disconnect(params = %{reason: {:remote, :closed}, conn: conn}, state) do
    IO.puts "Abruptly disconnected from #{conn.host} by server!"
    {:ok, state}
  end

  def handle_cast({:voice_update, guild_id, session_id, token, endpoint}, state) do
    alias LavaPotion.Struct.VoiceUpdate
    event = %{guild_id: guild_id, token: token, endpoint: endpoint}
    update = Poison.encode!(%VoiceUpdate{guildId: guild_id, sessionId: session_id, event: event})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:play, guild_id, track}, state) do
    alias LavaPotion.Struct.Play
    update = Poison.encode!(%Play{guildId: guild_id, track: track})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:volume, guild_id, volume}, state) do
    alias LavaPotion.Struct.Volume
    update = Poison.encode!(%Volume{guildId: guild_id, volume: volume})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:seek, guild_id, position}, state) do
    alias LavaPotion.Struct.Seek
    update = Poison.encode!(%Seek{guildId: guild_id, position: position})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:pause, guild_id, pause}, state) do
    alias LavaPotion.Struct.Pause
    update = Poison.encode!(%Pause{guildId: guild_id, pause: pause})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:destroy, guild_id}, state) do
    alias LavaPotion.Struct.Destroy
    update = Poison.encode!(%Destroy{guildId: guild_id})
    {:reply, {:text, update}, state}
  end

  def handle_cast({:stop, guild_id}, state) do
    alias LavaPotion.Struct.Stop
    update = Poison.encode!(%Stop{guildId: guild_id})
    {:reply, {:text, update}, state}
  end

  def handle_frame(frame, state), do: {:ok, state}
end