defmodule LavaPotion.Api do
  import WebSockex

  def initialize(pid, guild_id, session_id, token, endpoint) when is_pid(pid) && is_binary(guild_id) && is_binary(token) && is_binary(endpoint) do
    cast(pid, {:voice_update, guild_id, session_id, token, endpoint})
  end

  def play(pid, guild_id, track) when is_pid(pid) && is_binary(guild_id) && is_binary(track) do
    cast(pid, {:play, guild_id, track})
  end

  def volume(pid, guild_id, volume) when is_pid(pid) && is_binary(guild_id) && is_number(volume) && volume >= 0 && volume <= 1000 do
    cast(pid, {:volume, guild_id, volume})
  end

  def seek(pid, guild_id, position) when is_pid(pid) && is_binary(guild_id) && is_number(position) do
    cast(pid, {:seek, guild_id, position})
  end

  def pause(pid, guild_id) when is_pid(pid) && is_binary(guild_id), do: cast(pid, {:pause, guild_id, true})
  def resume(pid, guild_id) when is_pid(pid) && is_binary(guild_id), do: cast(pid, {:pause, guild_id, false})
  def stop(pid, guild_id) when is_pid(pid) && is_binary(guild_id), do: cast(pid, {:stop, guild_id})
  def destroy(pid, guild_id) when is_pid(pid) && is_binary(guild_id), do: cast(pid, {:destroy, guild_id})
end