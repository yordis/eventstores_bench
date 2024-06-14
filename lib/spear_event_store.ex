defmodule SpearEventStore do
  use Spear.Client, otp_app: :eventstores_bench

  alias Testcontainers.EventStoreDBContainer

  def start_container do
    esdb_config =
      EventStoreDBContainer.new()
      |> Testcontainers.ContainerBuilder.build()

    {:ok, container} = Testcontainers.start_container(esdb_config)

    {:ok, pid} =
      SpearEventStore.start_link(
        connection_string: EventStoreDBContainer.connection_uri(esdb_config)
      )

    %{container: container, pid: pid}
  end

  def stop_container(%{container: container, pid: pid}) do
    Testcontainers.stop_container(container.container_id)
    Process.exit(pid, :normal)
  end
end
