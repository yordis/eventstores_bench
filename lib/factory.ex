defmodule Factory do
  def create_event(event_id, attrs) do
    number = attrs[:number] || 1
    correlation_id = UUID.uuid4()
    causation_id = UUID.uuid4()
    event_id = event_id || UUID.uuid4()
    event = %EventStore.EventData{
      event_id: event_id,
      correlation_id: correlation_id,
      causation_id: causation_id,
      event_type: "Elixir.MyEvent",
      data: %MyEvent{event: number - 1},
      metadata: %{"user" => "user@example.com"}
    }

    case attrs[:transform_event] do
      nil -> event
      transform_event -> transform_event.(event)
    end
  end

  def create_events(number_of_events, attrs \\ %{}) when number_of_events > 0 do
    initial_event_number = attrs[:initial_event_number] || 1

    1..number_of_events
    |> Enum.map(&create_event(nil, %{
      number: initial_event_number + &1,
      transform_event: attrs[:transform_event]
    }))
  end

  def to_spear_event(event) do
    custom_metadata =
      event.metadata
      |> Map.put("$correlationId", event.correlation_id)
      |> Map.put("$causationId", event.causation_id)
      |> Jason.encode!()

    Spear.Event.new(event.event_type, event.data, custom_metadata: custom_metadata)
  end
end
