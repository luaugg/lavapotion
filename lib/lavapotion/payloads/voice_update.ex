defmodule LavaPotion.Payloads.VoiceUpdate do
  @derive Jason.Encoder
  defstruct [:op, :guildId, :sessionId, :event]
end
