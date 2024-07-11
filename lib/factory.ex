defmodule Factory do
  def create_event(event_id, number \\ 1) do
    correlation_id = UUID.uuid4()
    causation_id = UUID.uuid4()
    event_id = event_id || UUID.uuid4()

    %EventStore.EventData{
      event_id: event_id,
      correlation_id: correlation_id,
      causation_id: causation_id,
      event_type: "Elixir.MyEvent",
      data: %MyEvent{event: number - 1},
      metadata: %{"user" => "user@example.com"}
    }
  end

  def create_events(number_of_events, initial_event_number \\ 1) when number_of_events > 0 do
    1..number_of_events
    |> Enum.map(&create_event(nil, initial_event_number + &1))
  end

  def to_spear_events(events) do
    Enum.map(events, fn event ->
      custom_metadata =
        event.metadata
        |> Map.put("$correlationId", event.correlation_id)
        |> Map.put("$causationId", event.causation_id)
        |> Jason.encode!()

      Spear.Event.new(event.event_type, event.data, custom_metadata: custom_metadata)
    end)
  end
end
