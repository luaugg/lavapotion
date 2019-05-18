defmodule LavaPotion.Payloads.Volume do
  @derive Jason.Encoder
  defstruct [:guildId, :volume, op: "volume"]
end
