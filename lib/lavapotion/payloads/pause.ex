defmodule LavaPotion.Payloads.Pause do
  @derive Jason.Encoder
  defstruct [:guildId, :pause, op: "pause"]
end
