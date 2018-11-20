defmodule LavaPotionTest do
  use ExUnit.Case

  test "conn test" do
    client = LavaPotion.Struct.Client.new(user_id: "")
    nd = LavaPotion.Struct.Node.new(client: client, address: "localhost")
    {:ok, _} = LavaPotion.Struct.Node.start_link(nd)
  end
end
