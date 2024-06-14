defmodule EventstoresBenchTest do
  use ExUnit.Case
  doctest EventstoresBench

  test "greets the world" do
    assert EventstoresBench.hello() == :world
  end
end
