defmodule LavaPotion.Struct.Node do
  use WebSockex

  alias LavaPotion.Struct.{Client, Player}
  alias LavaPotion.Payloads.{EmptyBody, Pause, Volume, Play, VoiceUpdate}

  require Logger

  defstruct [:authorization, :port, :host, :client, :absolute]

  @type t :: %__MODULE__{}
  @type node_option :: {:client, Client.t()} | {:host, String.t()} | {:authorization, String.t()} | {:absolute, boolean()}
  @type new_node_error :: {:error, :client} | {:error, :host} | {:error, :authorization} | {:error, :absolute} | {:error, :port}

  @spec new!([node_option]) :: t
  def new!([client: client = %Client{}, host: host, port: port, authorization: authorization, absolute: absolute])
      when is_binary(host) and is_number(port) and is_binary(authorization) and is_boolean(absolute) do
    %__MODULE__{client: client, port: port, host: host, authorization: authorization, absolute: absolute}
  end

  @spec new([node_option]) :: {:ok, t} | new_node_error
  def new([client: client, host: host, port: port, authorization: authorization, absolute: absolute]) do
    cond do
      not (Map.get(client, :__struct__) == Client) ->
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

  @spec start_link(t) :: {:ok, pid()} | {:error, term()}
  def start_link(mod = %__MODULE__{}) do
    start_link_with_url(mod, conn_url(mod))
  end

  @spec start_link_with_url(t(), String.t()) :: {:ok, pid()} | {:error, term()}
  defp start_link_with_url(mod = %__MODULE__{client: %Client{user_id: user_id, num_shards: num_shards}, authorization: authorization}, url) do
    extra_headers = ["User-Id": user_id, "Authorization": authorization, "Num-Shards": num_shards]
    result = WebSockex.start_link(url, __MODULE__, %{}, extra_headers: extra_headers, handle_initial_conn_failure: true, async: true)
    if elem(result, 0) === :ok do
      {:ok, pid} = result
      ets_table_name = table_name(user_id, url)
      if :ets.whereis(ets_table_name) == :undefined do
        :ets.new(ets_table_name, [:set, :public, :named_table])
      end
      :ets.insert(ets_table_name, {url, %{pid: pid, node: mod, stats: nil, players: %{}}})
    end
    result
  end

  @spec table_name(String.t() | Client.t(), String.t()) :: atom()
  def table_name(user_id, url) when is_binary(user_id) and is_binary(url), do: :"#{user_id}-#{url}"
  def table_name(%Client{user_id: user_id}, url), do: table_name(user_id, url)

  @spec pid(String.t(), String.t()) :: pid()
  def pid(user_id, url) do
    [{_, %{pid: pid}}] = :ets.lookup(table_name(user_id, url), url)
    pid
  end

  @spec pid(t) :: pid()
  def pid(mod = %__MODULE__{client: %Client{user_id: user_id}}), do: pid(user_id, conn_url(mod))

  @spec conn_url(t) :: String.t()
  def conn_url(%__MODULE__{host: host, absolute: true}), do: host
  def conn_url(%__MODULE__{host: host, port: port}), do: "ws://#{host}:#{port}"

  def handle_cast({:voice_update, %Player{session_id: session_id, voice_token: voice_token, endpoint: endpoint, guild_id: guild_id}}, state) do
    event = %{guild_id: guild_id, token: voice_token, endpoint: endpoint}
    {result, term} = Jason.encode(%VoiceUpdate{guildId: guild_id, sessionId: session_id, event: event})
    case result do
      :ok -> {:reply, {:text, {:voice_update, term}}, state}
      :error ->
        Logger.warn "Failed to encode JSON Voice Update Data -> Guild ID: #{guild_id}"
        {:ok, state}
      _ ->
        {:close, {1006, "Illegal Voice Update Encoding Result -> Guild ID: #{guild_id}"}, state}
    end
  end
end
