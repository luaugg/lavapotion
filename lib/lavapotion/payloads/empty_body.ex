defmodule LavaPotion.Payloads.EmptyBody do
  @derive Jason.Encoder
  defstruct [:op, :guildId]
end
