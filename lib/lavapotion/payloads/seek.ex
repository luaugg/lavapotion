defmodule LavaPotion.Payloads.Seek do
  defstruct [:guildId, :position, op: "seek"]
end
