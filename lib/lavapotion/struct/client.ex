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

defmodule LavaPotion.Struct.Client do
  defstruct default_password: "youshallnotpass", default_port: 2333, user_id: nil, shard_count: 1


  @typedoc """

  """
  @type t :: %__MODULE__{}

  def new(opts) do
    user_id = opts[:user_id]
    if !is_binary(user_id) do
      raise "user id not a binary string or == nil"
    end

    shard_count = opts[:shard_count] || 1
    if !is_number(shard_count) do
      raise "shard count not a number or == nil"
    end

    default_port = opts[:default_port] || 2333
    if !is_number(default_port) do
      raise "default port not a number or == nil"
    end

    default_password = opts[:default_password] || "youshallnotpass"
    if !is_binary(default_password) do
      raise "default password not a binary string or == nil"
    end

    %__MODULE__{default_password: default_password, default_port: default_port, user_id: user_id, shard_count: shard_count}
  end
end