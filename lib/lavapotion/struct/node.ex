defmodule LavaPotion.Struct.Node do
  use WebSockex

  alias LavaPotion.Struct.Client

  require Logger

  defstruct [:authorization, :port, :host, :client]

  def new!([client: client = %Client{}, host: host, port: port, authorization: authorization])
      when is_binary(host) and is_number(port) and is_binary(authorization) do
    %__MODULE__{client: client, port: port, host: host, authorization: authorization}
  end

  def new([client: client, host: host, port: port, authorization: authorization]) do
    cond do
      not Map.get(client, :__struct__) == Client ->
        {:error, :client}
      not is_binary(host) ->
        {:error, :host}
      not is_number(port) ->
        {:error, :port}
      not (is_nil(authorization) or is_binary(authorization)) ->
        {:error, :authorization}
      true ->
        {:ok, %__MODULE__{client: client, host: host, port: port, authorization: authorization}}
    end
  end
end