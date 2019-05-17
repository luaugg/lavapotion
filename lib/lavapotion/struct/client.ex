defmodule LavaPotion.Struct.Client do
  defstruct [:user_id, :num_shards]

  def new!([user_id: user_id, num_shards: num_shards]) when is_binary(user_id) and is_number(num_shards) do
    %__MODULE__{user_id: user_id, num_shards: num_shards}
  end

  def new([user_id: user_id, num_shards: num_shards]) do
    cond do
      not is_binary(user_id) ->
        {:error, :user_id}
      not is_number(num_shards) ->
        {:error, :num_shards}
      true ->
        {:ok, %__MODULE__{user_id: user_id, num_shards: num_shards}}
    end
  end
end