defmodule MyEvent do
  @derive Jason.Encoder
  defstruct [:event]
end
