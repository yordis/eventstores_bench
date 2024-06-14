defmodule AppendBench do
  alias EventStore.UUID

  def run do
    {:ok, _} = Testcontainers.start_link()
    commanded_container = CommandedEventStore.start_container()
    spear_container = SpearEventStore.start_container()

    total_events = 15
    events = Factory.create_events(total_events)
    spear_events = Factory.to_spear_events(events)

    [1, 5, 10, 15, 20, 30, 50]
    |> Enum.reduce(%{}, fn concurrency, acc ->
      acc
      |> Map.put_new(
        "commanded - append(total_events: #{total_events}, concurrency: #{concurrency})",
        fn ->
          concurrently(concurrency, fn stream_uuid ->
            :ok = CommandedEventStore.append_to_stream(stream_uuid, 0, events)
          end)
        end
      )
      |> Map.put_new(
        "spear - append(total_events: #{total_events}, concurrency: #{concurrency})",
        fn ->
          concurrently(concurrency, fn stream_uuid ->
            :ok = SpearEventStore.append(spear_events, stream_uuid, expect: :empty)
          end)
        end
      )
    end)
    |> Benchee.run(formatters: [Benchee.Formatters.HTML, Benchee.Formatters.Console])

    CommandedEventStore.stop_container(commanded_container)
    SpearEventStore.stop_container(spear_container)
  end

  defp concurrently(concurrency, callback) do
    Enum.map(1..concurrency, fn _ ->
      stream_uuid = UUID.uuid4()
      Task.async(fn -> callback.(stream_uuid) end)
    end)
    |> Task.await_many(:infinity)
  end
end
