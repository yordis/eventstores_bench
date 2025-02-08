# defmodule EventstoresBench.EventStore do
#   use EventStore, otp_app: :eventstores_bench
# end

defmodule EventstoresBench.Application do
  use Commanded.Application,
    otp_app: :eventstores_bench,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: EventstoresBench.EventStore
    ],
    pubsub: :local,
    registry: :local

  # router(EventstoresBench.Router)
end
