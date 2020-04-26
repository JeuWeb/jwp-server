defmodule JwpWeb.ConsoleChannelsListComponent do
  use Phoenix.LiveComponent
  require Logger
  require Record
  alias Jwp.Auth.SocketAuth

  # A small record to track our channel menu
  Record.defrecordp(:rchan, short_topic: nil, subscribed: false)

  def mount(socket) do
    # schedule_refresh()
    socket =
      socket
      |> assign(:channels, %{})

    {:ok, socket}
  end

  def update(assigns, socket) do
    # When updated, we receive the new list of active channels from
    # the parent view. We will add those to our current list of
    # channels, only if they are not already there
    # (to prevent changing their visibility state)
    IO.inspect(assigns, label: "CHILD UPDATE ASSIGNS")

    channels =
      for new_chan <- assigns.active_channels, reduce: socket.assigns.channels do
        channels ->
          case Map.has_key?(channels, new_chan) do
            true ->
              channels

            false ->
              [_, _, short_topic] = String.split(new_chan, ":", parts: 3)
              chan = rchan(short_topic: short_topic)
              Map.put(channels, new_chan, chan)
          end
      end

    socket =
      socket
      |> assign(:channels, channels)
      |> assign(:app_id, assigns.app_id)

    {:ok, socket}
  end

  @spec handle_event(<<_::96, _::_*16>>, map, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("unsubscribe_to", %{"topic" => topic}, socket) do
    Phoenix.PubSub.unsubscribe(Jwp.PubSub, topic)
    {:noreply, toggle_subscription(socket, topic, false)}
  end

  def handle_event("subscribe_to", %{"topic" => "jwp:" <> scope = topic}, socket) do
    case SocketAuth.check_scope(socket, scope) do
      :ok ->
        :ok = Phoenix.PubSub.subscribe(Jwp.PubSub, topic)
        {:noreply, toggle_subscription(socket, topic, true)}

      _ ->
        exit({:bad_scope, scope})
    end
  end

  defp toggle_subscription(socket, topic, sub?) do
    channels = socket.assigns.channels

    channels =
      case Map.get(channels, topic, nil) do
        nil -> socket
        rchan() = chan -> Map.put(channels, topic, rchan(chan, subscribed: sub?))
      end
      |> IO.inspect(label: "CHANNELS")

    assign(socket, :channels, channels)
  end
end
