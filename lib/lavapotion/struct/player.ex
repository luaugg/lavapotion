defmodule LavaPotion.Struct.Player do
  defstruct [:session_id, :voice_token, :endpoint, :guild_id, :paused, :track, :volume, :node_pid, :is_real, :connected]
end
