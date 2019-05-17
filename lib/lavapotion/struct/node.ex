defmodule LavaPotion.Struct.Node do
  use WebSockex

  alias LavaPotion.Struct.Client

  require Logger

  defstruct [:authorization, :port, :host, :client, :absolute]

  def new!([client: client = %Client{}, host: host, port: port, authorization: authorization, absolute: absolute])
      when is_binary(host) and is_number(port) and is_binary(authorization) and is_boolean(absolute) do
    %__MODULE__{client: client, port: port, host: host, authorization: authorization, absolute: absolute}
  end

  def new([client: client, host: host, port: port, authorization: authorization, absolute: absolute]) do
    cond do
      not Map.get(client, :__struct__) == Client ->
        {:error, :client}
      not is_binary(host) ->
        {:error, :host}
      not is_number(port) ->
        {:error, :port}
      not (is_nil(authorization) or is_binary(authorization)) ->
        {:error, :authorization}
      not is_boolean(absolute) ->
        {:error, :absolute}
      true ->
        {:ok, %__MODULE__{client: client, host: host, port: port, authorization: authorization, absolute: absolute}}
    end
  end

  def start_link(mod = %__MODULE__{host: host, absolute: true}), do: start_link_with_url(mod, host)
  def start_link(mod = %__MODULE__{host: host, port: port}), do: start_link_with_url(mod, "ws://#{host}:#{port}")

  defp start_link_with_url(mod = %__MODULE__{client: %Client{user_id: user_id, num_shards: num_shards}, authorization: authorization}, url) do
    extra_headers = ["User-Id": user_id, "Authorization": authorization, "Num-Shards": num_shards]
    result = WebSockex.start_link(url, __MODULE__, %{}, extra_headers: extra_headers, handle_initial_conn_failure: true, async: true)
    if elem(result, 0) === :ok do
      {:ok, pid} = result
      ets_table_name = "#{user_id}-#{host}"
      if :ets.whereis(ets_table_name) === :undefined do
        :ets.new(ets_table_name, [:set, :public, :named_table])
      end
      :ets.insert(ets_table_name, {host, %{pid: pid, node: mod, stats: nil, players: %{}}})
    end
    result
  end
end