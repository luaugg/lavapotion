defmodule LavaPotion.Struct.Client do
  defstruct [:user_id, :num_shards]

  @type t :: %__MODULE__{}
  @type new_client_error :: {:error, :user_id} | {:error, :num_shards}
  @type client_option :: {:user_id, String.t()} | {:num_shards, integer()}

  @spec new!([client_option]) :: t
  def new!([user_id: user_id, num_shards: num_shards]) when is_binary(user_id) and is_number(num_shards) do
    %__MODULE__{user_id: user_id, num_shards: num_shards}
  end

  @spec new([client_option]) :: {:ok, t} | new_client_error
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
