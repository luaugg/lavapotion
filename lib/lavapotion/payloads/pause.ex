defmodule LavaPotion.Payloads.Pause do
  @derive Jason.Encoder
  defstruct [:op, :guildId, :pause]
end
