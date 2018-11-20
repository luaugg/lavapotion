defmodule LavaPotion.Struct.Node do
  use WebSockex
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

  def start_link(mod), do: WebSockex.start_link("ws://#{mod.address}:#{mod.port}", __MODULE__, %{},
      extra_headers: ["User-Id": mod.client.user_id, "Authorization": mod.password, "Num-Shards": mod.client.shard_count])

  def handle_connect(conn, state) do
    IO.puts "Connected to #{conn.host}!"
    {:ok, state}
  end

  def handle_disconnect(params = %{reason: {:local, _}}, state) do
    IO.puts "Client disconnected from #{params[:conn].host}!"
    {:ok, state}
  end

  def handle_disconnect(params = %{reason: {:local, _, _}}, state) do
    IO.puts "Client disconnected from #{params[:conn].host}!"
    {:ok, state}
  end

  def handle_disconnect(params = %{reason: {:remote, code, message}, attempt_number: attempt_number}, state) when attempt_number < 5 do
    IO.puts "Disconnected from #{params[:conn].host} by server with code: #{code} and message: #{message}! Reconnecting..."
    {:reconnect, state}
  end

  def handle_disconnect(params = %{reason: {:remote, code, message}}, state) do
    IO.puts "Disconnected from #{params[:conn].host} by server with code: #{code} and message: #{message}!"
    {:ok, state}
  end

  def handle_disconnect(params = %{reason: {:remote, :closed}}, state) do
    IO.puts "Abruptly disconnected from #{params[:conn].host} by server!"
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    IO.puts "Received Message: #{inspect msg}"
    {:ok, state}
  end

  def handle_cast({:send, {:text, msg} = frame}, state) do
    IO.puts "Sending Message: #{inspect msg}"
    {:reply, frame, state}
  end
end