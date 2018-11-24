# Copyright 2018 Sam Pritchard
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule LavaPotion.Struct.VoiceUpdate do
  @derive [Poison.Encoder]
  defstruct [:guildId, :sessionId, :event, op: "voiceUpdate"]
end

defmodule LavaPotion.Struct.Play do
  @derive [Poison.Encoder]
  defstruct [:guildId, :track, op: "play"] # startTime and endTime disabled for now
end

defmodule LavaPotion.Struct.Stop do
  @derive [Poison.Encoder]
  defstruct [:guildId, op: "stop"]
end

defmodule LavaPotion.Struct.Destroy do
  @derive [Poison.Encoder]
  defstruct [:guildId, op: "destroy"]
end

defmodule LavaPotion.Struct.Volume do
  @derive [Poison.Encoder]
  defstruct [:guildId, :volume, op: "volume"]
end

defmodule LavaPotion.Struct.Pause do
  @derive [Poison.Encoder]
  defstruct [:guildId, :pause, op: "pause"]
end

defmodule LavaPotion.Struct.Seek do
  @derive [Poison.Encoder]
  defstruct [:guildId, :position, op: "seek"]
end

defmodule LavaPotion.Struct.Equalizer do
  @derive [Poison.Encoder]
  defstruct [:guildId, :bands, op: "equalizer"]
end

defmodule LavaPotion.Struct.LoadTrackResponse do
  @derive [Poison.Encoder]
  defstruct [:loadType, :playlistInfo, :tracks]
end