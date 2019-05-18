defmodule LavaPotion.Payloads.Play do
  @derive Jason.Encoder
  defstruct [:op, :guildId, :track, :startTime, :endTime, :noReplace]
end
