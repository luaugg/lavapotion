defmodule LavaPotion.Struct.Node do
  use WebSockex

  alias LavaPotion.Struct.{Client, Player}
  alias LavaPotion.Payloads.{EmptyBody, Pause, Volume, Play, VoiceUpdate}
  alias LavaPotion.Stage.Producer

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

  def handle_cast({:voice_update, player = %Player{session_id: session_id, voice_token: voice_token, endpoint: endpoint, guild_id: guild_id, is_real: false}}, state) do
    event = %{guild_id: guild_id, token: voice_token, endpoint: endpoint}
    {result, term} = Jason.encode(%VoiceUpdate{guildId: guild_id, sessionId: session_id, event: event})
    case result do
      :ok -> {:reply, {:text, {:outgoing, :voice_update, term, {player}}}, state}
      :error ->
        %Jason.DecodeError{data: data, position: position, token: token} = term
        Logger.warn "Failed to encode JSON Voice Update Data -> Guild ID: #{guild_id}, Position: #{position}, Token: #{token}, Data: #{data}"
        {:ok, state}
      _ ->
        {:close, {1006, "Illegal Voice Update Encoding Result -> Guild ID: #{guild_id}"}, state}
    end
  end

  def handle_cast({:play, player = %Player{guild_id: guild_id, is_real: true}, track = {data, _info}, start_time, end_time, no_replace}, state) do
    play = %Play{}
    |> Map.put(:guildId, guild_id)
    |> Map.put(:startTime, start_time)
    |> Map.put(:endTime, end_time)
    |> Map.put(:noReplace, no_replace)
    |> Map.put(:track, data)
    {result, term} = Jason.encode(play)
    case result do
      :ok -> {:reply, {:text, {:outgoing, :play, term, {player, track}}}, state}
      :error ->
        %Jason.DecodeError{data: data, position: position, token: token} = term
        Logger.warn "Failed to encode JSON Play Data -> Guild ID: #{guild_id}, Position: #{position}, Token: #{token}, Data: #{data}"
        {:ok, state}
      _ ->
        {:close, {1006, "Illegal Play Encoding Result -> Guild ID: #{guild_id}"}, state}
    end
  end

  def handle_cast({:pause, player = %Player{guild_id: guild_id, is_real: true}, paused}, state) do
    pause = %Pause{guildId: guild_id, pause: paused}
    {result, term} = Jason.encode(pause)
    case result do
      :ok -> {:reply, {:text, {:outgoing, :pause, term, {player, paused}}}, state}
      :error ->
        %Jason.DecodeError{data: data, position: position, token: token} = term
        Logger.warn "Failed to encode JSON Pause Data -> Guild ID: #{guild_id}, Position: #{position}, Token: #{token}, Data: #{data}"
        {:ok, state}
      _ ->
        {:close, {1006, "Illegal Pause Encoding Result -> Guild ID: #{guild_id}"}}
    end
  end

  def handle_cast({:send, {:outgoing, event_type, json, data}}, state) do
    Producer.notify({:handle_outgoing, {event_type, data}})
    {:reply, {:text, json}, state}
  end
end
