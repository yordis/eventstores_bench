# SPDX-License-Identifier: MIT
defmodule Testcontainers.EventStoreDBContainer do
  @moduledoc """
  Provides functionality for creating and managing EventStoreDB container configurations.
  """

  alias Testcontainers.EventStoreDBContainer
  alias Testcontainers.ContainerBuilder
  alias Testcontainers.Container

  @default_image "eventstore/eventstore"
  @default_tag "latest"
  @default_image_with_tag "#{@default_image}:#{@default_tag}"
  @default_port 2113
  @default_wait_timeout 60_000

  @enforce_keys [:image, :port, :wait_timeout]
  defstruct [:image, :port, :wait_timeout]

  def new do
    %__MODULE__{
      image: @default_image_with_tag,
      port: @default_port,
      wait_timeout: @default_wait_timeout
    }
  end

  def with_image(%__MODULE__{} = config, image) when is_binary(image) do
    %{config | image: image}
  end

  def default_image, do: @default_image

  def default_port, do: @default_port

  @doc """
  Retrieves the port mapped by the Docker host for the Cassandra container.
  """
  def port(%Container{} = container), do: Container.mapped_port(container, @default_port)

  @doc """
  Generates the connection URL for accessing the Cassandra service running within the container.
  """
  def connection_uri(%Container{} = _container) do
    # Fix: use port(container) instead of @default_port
    "esdb://#{Testcontainers.get_host()}:#{@default_port}"
  end

  defimpl ContainerBuilder do
    import Container

    @impl true
    @spec build(%EventStoreDBContainer{}) :: %Container{}
    def build(%EventStoreDBContainer{} = config) do
      if not String.starts_with?(config.image, EventStoreDBContainer.default_image()) do
        raise ArgumentError,
          message:
            "Image #{config.image} is not compatible with #{EventStoreDBContainer.default_image()}"
      end

      new(config.image)
      |> with_exposed_port(config.port)
      |> with_environment(:EVENTSTORE_CLUSTER_SIZE, "1")
      |> with_environment(:EVENTSTORE_INSECURE, "true")
    end

    @impl true
    @spec after_start(%EventStoreDBContainer{}, %Container{}, %Tesla.Env{}) :: :ok
    def after_start(_config, _container, _conn), do: :ok
  end
end
