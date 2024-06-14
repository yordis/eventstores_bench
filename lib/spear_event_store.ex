defmodule SpearEventStore do
  use Spear.Client, otp_app: :eventstores_bench

  def start_container do
    {:ok, container} =
      Testcontainers.start_container(%Testcontainers.Container{
        image: "eventstore/eventstore:latest",
        environment: %{
          EVENTSTORE_CLUSTER_SIZE: "1",
          EVENTSTORE_INSECURE: "true"
        },
        exposed_ports: [2113, 2113]
      })

    {:ok, pid} =
      SpearEventStore.start_link(connection_string: "esdb://#{container.ip_address}:2113")

    %{container: container, pid: pid}
  end

  def stop_container(%{container: container, pid: pid}) do
    Testcontainers.stop_container(container.container_id)
    Process.exit(pid, :normal)
  end
end
