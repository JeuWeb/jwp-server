defmodule JwpWeb.MultiTenantSocket do
  # use Phoenix.Socket, log: :debug
  require Logger
  alias JwpWeb.MultiTenantSocket.Serializer

  @app_id_length 10
  @app_id_pad ?0
  @app_id_sep ?:

  def app_id_length(), do: @app_id_length
  def app_id_pad(), do: @app_id_pad
  def app_id_sep(), do: @app_id_sep

  # Using Phoenix.Socket

  ## User API

  import Phoenix.Socket
  @behaviour Phoenix.Socket
  @before_compile Phoenix.Socket
  Module.register_attribute(__MODULE__, :phoenix_channels, accumulate: true)
  @phoenix_socket_options [log: :debug]

  ## Callbacks

  @behaviour Phoenix.Socket.Transport

  @doc false
  def child_spec(opts) do
    IO.inspect(opts, label: :child_spec_opts)
    Phoenix.Socket.__child_spec__(__MODULE__, opts, @phoenix_socket_options)
  end

  @doc false
  def connect(map) do
    IO.inspect(map, label: :connect_map)
    map = put_in(map.options[:serializer], [{Serializer, "~> 2.0"}])
    Phoenix.Socket.__connect__(__MODULE__, map, @phoenix_socket_options)
  end

  @doc false
  def init(state) do
    IO.inspect(state, label: :init_state)
    Phoenix.Socket.__init__(state)
  end

  @doc false
  def handle_in(
        {message, opcode} = msg_wrapper,
        {_, %Phoenix.Socket{assigns: %{app_id: app_id}}} = state
      ) do
    IO.inspect(message, label: :handle_in_message)
    IO.inspect(state, label: :handle_in_state)
    # The serializer will prefix the topic with the app_id and return a
    # pre-decoded message. Then Phoenix.Socket.__in__ will pass the message
    # again to the serializer, and it will just return it as-is. This is to
    # avoid to duplicate Phoenix.Socket code. At this point the app_id has been
    # verified and is trusted.
    message = Serializer.pre_decode!(message, app_id)
    Phoenix.Socket.__in__({message, opcode}, state)
  end

  @doc false
  def handle_info(message, state) do
    Phoenix.Socket.__info__(message, state)
  end

  @doc false
  def terminate(reason, state) do
    Phoenix.Socket.__terminate__(reason, state)
  end

  ## Channels
  def __channel__(<<app_id::binary-size(@app_id_length), @app_id_sep, short_topic::binary>>) do
    {JwpWeb.MainChannel, []}
  end

  def __channel__("jwp:" <> _) do
    {JwpWeb.MainChannel, []}
  end

  def connect(%{"app_id" => claim_app_id, "auth" => token}, socket, _) do
    case Jwp.Auth.SocketAuth.verify_socket_token(claim_app_id, token) do
      {:ok, socket_id} ->
        socket =
          socket
          |> assign(:app_id, claim_app_id)
          |> assign(:socket_id, socket_id)

        {:ok, socket}

      {:error, reason} ->
        Logger.error(inspect(reason))
        :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.app_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     JwpWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end

defmodule JwpWeb.MultiTenantSocket.Serializer do
  @behaviour Phoenix.Socket.Serializer

  @app_id_length JwpWeb.MultiTenantSocket.app_id_length()
  @app_id_pad JwpWeb.MultiTenantSocket.app_id_pad()
  @app_id_sep JwpWeb.MultiTenantSocket.app_id_sep()

  alias Phoenix.Socket.{Broadcast, Message, Reply}

  @impl true
  def fastlane!(%Broadcast{} = msg) do
    data =
      Phoenix.json_library().encode_to_iodata!([
        nil,
        nil,
        remove_app_prefix(msg.topic),
        msg.event,
        msg.payload
      ])

    {:socket_push, :text, data}
  end

  @impl true
  def encode!(%Reply{} = reply) do
    IO.inspect(reply, label: "encode reply")

    data =
      [
        reply.join_ref,
        reply.ref,
        remove_app_prefix(reply.topic),
        "phx_reply",
        %{status: reply.status, response: reply.payload}
      ]
      |> IO.inspect(label: "=>")

    {:socket_push, :text, Phoenix.json_library().encode_to_iodata!(data)}
  end

  def encode!(%Message{} = msg) do
    IO.inspect(msg, label: "encode msg")

    data =
      [
        msg.join_ref,
        msg.ref,
        remove_app_prefix(msg.topic),
        msg.event,
        msg.payload
      ]
      |> IO.inspect(label: "=>")

    {:socket_push, :text, Phoenix.json_library().encode_to_iodata!(data)}
  end

  @impl true
  def decode!({:pre_decoded, message}, _opts) do
    message
  end

  def pre_decode!(raw_message, app_id) do
    [join_ref, ref, topic, event, payload | _] =
      Phoenix.json_library().decode!(raw_message)
      |> IO.inspect()

    # Pad the app_id to a fixed length. The app id is formed with 1-byte
    # characters so we actually mean fixed byte-length.
    # @todo use only numbers in app ids.
    # app_id = pad_id(app_id)
    # topic = app_id <> <<@app_id_sep>> <> topic
    topic =
      case {topic, event} do
        {"phoenix", "heartbeat"} -> topic
        _ -> "jwp:#{app_id}:#{topic}"
      end

    {:pre_decoded,
     %Message{
       topic: topic,
       event: event,
       payload: payload,
       ref: ref,
       join_ref: join_ref
     }}
  end

  defp pad_id(app_id) when byte_size(app_id) < @app_id_length do
    size = byte_size(app_id)
    pad_length = @app_id_length - size

    # We will use the "0" character representation to pad the
    pad =
      @app_id_pad
      |> List.duplicate(pad_length)
      |> :binary.list_to_bin()

    <<pad::binary-size(pad_length), app_id::binary>>
  end

  defp pad_id(app_id) when byte_size(app_id) == @app_id_length do
    app_id
  end

  defp pad_id(app_id) when byte_size(app_id) > @app_id_length do
    raise ArgumentError, "bad app id size"
  end

  defp remove_app_prefix("jwp:dev:" <> x), do: x
end
