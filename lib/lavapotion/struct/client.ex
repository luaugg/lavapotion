defmodule LavaPotion.Struct.Client do
  defstruct [:user_id, :num_shards]

  def new(opts) do
    user_id = opts[:user_id]
    num_shards = opts[:num_shards]
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