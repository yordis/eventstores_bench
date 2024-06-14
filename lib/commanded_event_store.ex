defmodule CommandedEventStore do
  use EventStore, otp_app: :eventstores_bench

  alias Testcontainers.PostgresContainer

  def start_container do
    pg_config =
      PostgresContainer.new()
      |> PostgresContainer.with_image("postgres:16")

    {:ok, container} = Testcontainers.start_container(pg_config)

    es_config = [
      username: pg_config.user,
      password: pg_config.password,
      database: pg_config.database,
      port: pg_config.port,
      hostname: container.ip_address,
      pool_size: 50,
      serializer: EventStore.JsonSerializer,
      schema: "public",
      column_data_type: "bytea"
    ]

    :ok = EventStore.Tasks.Init.exec(es_config, [])
    :ok = EventStore.Tasks.Migrate.exec(es_config, [])
    {:ok, pid} = CommandedEventStore.start_link(es_config)

    %{container: container, pid: pid}
  end

  def stop_container(%{container: container, pid: pid}) do
    Testcontainers.stop_container(container.container_id)
    Process.exit(pid, :normal)
  end
end
