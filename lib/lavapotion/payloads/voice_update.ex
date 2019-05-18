defmodule LavaPotion.Payloads.VoiceUpdate do
  @derive Jason.Encoder
  defstruct [:guildId, :sessionId, :event, op: "voiceUpdate"]
end
