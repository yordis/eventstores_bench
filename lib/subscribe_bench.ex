defmodule SubscribeBench do
  alias EventStore.UUID

  def run do
    {:ok, _} = Testcontainers.start_link()
    commanded_container = CommandedEventStore.start_container()
    spear_container = SpearEventStore.start_container()
    total_events = 15

    [1, 5, 10, 15, 20, 30, 50]
    |> Enum.reduce(%{}, fn concurrency, acc ->
      acc
      |> Map.put_new(
        "commanded - read(total_events: #{total_events}, concurrency: #{concurrency})",
        fn ->
          concurrently(%{
            concurrency: concurrency,
            append_callback: &commanded_append(&1, total_events),
            subscribe_callback: &commanded_subscribe(&1, &2, total_events)
          })
        end
      )
      |> Map.put_new(
        "spear - read(total_events: #{total_events}, concurrency: #{concurrency})",
        fn ->
          concurrently(%{
            concurrency: concurrency,
            append_callback: &spear_append(&1, total_events),
            subscribe_callback: &spear_subscribe(&1, &2, total_events)
          })
        end
      )
    end)
    |> Benchee.run(formatters: [Benchee.Formatters.HTML, Benchee.Formatters.Console])

    CommandedEventStore.stop_container(commanded_container)
    SpearEventStore.stop_container(spear_container)
  end

  defp spear_append(stream_uuid, total_events) do
    events =
      total_events
      |> Factory.create_events()
      |> Factory.to_spear_events()

    :ok = SpearEventStore.append(events, stream_uuid, expect: :any)
  end

  defp spear_subscribe(_stream_uuid, _index, total_events) do
    {:ok, subscription} =
      SpearEventStore.subscribe(self(), :all, filter: Spear.Filter.exclude_system_events())

    # {:ok, subscription} = SpearEventStore.subscribe(self(), stream_uuid, from: 0)

    for _i <- 1..total_events do
      receive do
        _event ->
          :ok
      end
    end

    :ok = SpearEventStore.cancel_subscription(subscription)
  end

  defp commanded_append(stream_uuid, total_events) do
    events = Factory.create_events(total_events)
    :ok = CommandedEventStore.append_to_stream(stream_uuid, :any_version, events)
  end

  defp commanded_subscribe(stream_uuid, index, total_events) do
    subscription_name = "subscription-#{index}"

    {:ok, subscription} =
      CommandedEventStore.subscribe_to_stream(
        stream_uuid,
        subscription_name,
        self(),
        []
      )

    for _i <- 1..total_events do
      receive do
        {:events, events} ->
          :ok = CommandedEventStore.ack(subscription, events)
      end
    end

    :ok = CommandedEventStore.unsubscribe_from_stream(stream_uuid, subscription_name)
  end

  defp concurrently(%{
         concurrency: concurrency,
         append_callback: append_callback,
         subscribe_callback: subscribe_callback
       }) do
    stream_uuid = UUID.uuid4()

    subs_tasks =
      Enum.map(1..concurrency, fn index ->
        Task.async(fn -> subscribe_callback.(stream_uuid, index) end)
      end)

    append_tasks =
      Enum.map(1..concurrency, fn _ -> Task.async(fn -> append_callback.(stream_uuid) end) end)

    Task.await_many(subs_tasks ++ append_tasks, :infinity)
  end
end
