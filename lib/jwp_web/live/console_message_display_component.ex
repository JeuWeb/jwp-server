defmodule JwpWeb.ConsoleMessageDisplayComponent do
  use Phoenix.LiveComponent
  alias Phoenix.Socket.Broadcast

  def mount(socket) do
    {:ok, assign(socket, :msg_id, 0)}
  end

  def update(%{last_message: nil}, socket) do
    # We will just Prepare the last message data for display and it will be
    # rendered by the template with phx-update=append
    {:ok, assign(socket, :message, nil)}
  end

  def update(%{last_message: last}, socket) do
    %Broadcast{event: event, payload: payload, topic: topic} = last
    [_,_,short_topic] = String.split(topic, ":", parts: 3)
    # We will just Prepare the last message data for display and it will be
    # rendered by the template with phx-update=append
    msg = %{event: event, short_topic: short_topic, payload: payload}
    socket = socket
      |> assign(:message, msg)
      |> assign(:msg_id, socket.assigns.msg_id + 1)
    {:ok, socket}
  end
end
