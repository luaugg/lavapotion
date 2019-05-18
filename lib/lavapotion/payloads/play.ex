defmodule LavaPotion.Payloads.Play do
  @derive Jason.Encoder
  defstruct [:guildId, :track, :startTime, :endTime, :noReplace, op: "play"]
end
