defmodule LavaPotion.Struct.Node do
  defstruct password: nil, port: nil, address: nil, stats: %{}, players: %{}, client: nil


  @typedoc """

  """
  @type t :: %__MODULE__{}

  def new!(opts) do
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
end