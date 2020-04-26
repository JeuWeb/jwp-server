defmodule JwpWeb.ConsoleLive do
  use Phoenix.LiveView
  require Logger
  alias Phoenix.Socket.Broadcast
  alias JwpWeb.ConsoleChannelsListComponent

  if Mix.env() == :prod do
    @refresh_channels_ms Jwp.PubSub.ChannelWitness.purge_cycle(:millisecond)
  else
    @refresh_channels_ms 500
  end

  def mount(%{"app_id" => app_id}, _, socket) do
    schedule_channels_refresh()

    socket = socket
      |> assign(:active_channels, [])
      |> assign(:app_id, app_id)
      |> assign(:messages, %{})
      |> fecth_active_channels()

    {:ok, socket}
  end


  # We subscribe the liveview process to the channels. We store this
  # information in the socket as the socket is used as our state, but
  # the websocket itself will not handle those channel message. They
  # will be sent to the process in handle_info.
  # defp subscribe_all(channels, socket, topics_in \\ []) do
  #   {new_topics, socket} =
  #     Enum.reduce(channels, {topics_in, socket}, fn chan, {topics, socket} ->
  #       if chan in topics do
  #         {topics, socket}
  #       else
  #         Phoenix.PubSub.subscribe(Jwp.PubSub, chan, [])
  #         {[chan | topics], socket}
  #       end
  #     end)

  #   assign(socket, :channels, new_topics)
  # end

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

  def handle_info(:refresh_channels_list, socket) do
    socket = fecth_active_channels(socket)
    {:noreply, socket}
  end

  def handle_info({:apply_transform, fun}, socket) do
    {:noreply, fun.(socket)}
  end

  def handle_info(info, socket) do
    Logger.warn("Unhandled info in #{__MODULE__}: #{inspect(info)}")
    {:noreply, socket}
  end

  def transform_after(time, fun) when is_integer(time) and is_function(fun, 1) do
    Process.send_after(self(), {:apply_transform, fun}, time)
  end

  defp fecth_active_channels(socket) do
    app_id = socket.assigns.app_id
    new_channels = Jwp.PubSub.ChannelWitness.get_active_channels(app_id)
    assign(socket, :active_channels, new_channels)
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

  defp schedule_channels_refresh() do
    transform_after(@refresh_channels_ms, fn socket ->
      schedule_channels_refresh()
      fecth_active_channels(socket)
    end)
  end
end
