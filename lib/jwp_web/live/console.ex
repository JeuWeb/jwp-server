defmodule JwpWeb.ConsoleLive do
  use Phoenix.LiveView
  require Logger
  alias Phoenix.Socket.Broadcast

  def render(assigns) do
    ~L"""
    <p>App: <%= @app_id %></p>
    <pre>App: <%= inspect @channels %></pre>
    <div id="all-chans-messages" style="display: flex">
      <%= for {channel, last_message} <- @messages do %>
          <div>
            <h4><%= channel %></h4>
            <div id="chan-<%= channel %>" phx-update="append" >
              <div id="<%= "#{channel}-#{last_message.id}" %>" style="display: flex">
                <code><%= last_message.event %>:</code>
                <pre><%= Jason.encode!(last_message.data) %></pre>
              </div>
            </div>
          </div>
      <% end %>
    </div>
    """
  end

  def mount(%{"app_id" => app_id}, _, socket) do
    active_channels = fecth_active_channels(app_id)
    socket = subscribe_all(active_channels, socket)

    socket =
      socket
      |> assign(:app_id, app_id)
      |> assign(:active_channels, active_channels)
      |> assign(:messages, %{})

    {:ok, socket}
  end

  defp fecth_active_channels(app_id) do
    Registry.select(Jwp.History.Registry, [{{:"$1", :"$2", app_id}, [], [{{:"$1"}}]}])
    |> Enum.map(&elem(&1, 0))
  end

  # We subscribe the liveview process to the channels. We store this
  # information in the socket as the socket is used as our state, but
  # the websocket itself will not handle those channel message. They
  # will be sent to the process in handle_info.
  defp subscribe_all(channels, socket, topics_in \\ []) do
    {new_topics, socket} =
      Enum.reduce(channels, {topics_in, socket}, fn chan, {topics, socket} ->
        if chan in topics do
          {topics, socket}
        else
          Phoenix.PubSub.subscribe(Jwp.PubSub, chan, [])
          {[chan | topics], socket}
        end
      end)

    assign(socket, :channels, new_topics)
  end

  # Match a pushed message from a client (because we have :tid).
  # Presence message are not matched
  def handle_info(%Broadcast{payload: %{tid: _tid}} = msg, socket) do
    IO.puts("CALL set_channel_message")
    {:noreply, set_channel_message(socket, msg)}
  end

  # Matches and ignores presence messages
  def handle_info(%Broadcast{event: event}, socket)
      when event in ["presence_state", "presence_diff"] do
    {:noreply, socket}
  end

  def handle_info(info, socket) do
    Logger.warn("Unhandled info in #{__MODULE__}: #{inspect(info)}")
    {:noreply, socket}
  end

  defp set_channel_message(
         socket,
         %Broadcast{
           event: event,
           payload: %{data: data, tid: %{"id" => msg_id, "time" => time}},
           topic: channel
         }
       ) do
    # current = socket.assigns.
    msg = %{event: event, data: data, time: time, id: msg_id}

    messages = Map.put(socket.assigns.messages, channel, msg)
    assign(socket, :messages, messages)
  end
end
