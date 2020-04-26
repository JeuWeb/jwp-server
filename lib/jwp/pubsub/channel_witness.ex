defmodule Jwp.PubSub.ChannelWitness do
  @moduledoc """
  This module implements a single GenServer that manages an ETS table
  and let fetch currently active channels for a given app.

  Whenever a push is made, the app_id and channel name is sent to the
  process and is stored in the table. If the entry already exists, it
  is simply replaced.

  Each entry has a limited time to live and is automatically deleted
  after some time.
  """
  use GenServer, restart: :permanent
  require Logger
  import Ex2ms

  @server __MODULE__
  @table __MODULE__

  # Channels flags have a TTL of 30 seconds, and purge cycle are also
  # done every 30 seconds. This means that a channel can be set as
  # active for up to one minute.
  @ttl_seconds 30
  # @cycle_ms @ttl_seconds * 1000
  @cycle_ms @ttl_seconds * 1000

  # We will make the ets insertion in the GenServer process so we do
  # not have to ensure ets:select_delete is atomic.
  def bump_channel(app_id, channel) do
    GenServer.cast(@server, {:insert, app_id, channel})
    :ok
  end

  def get_active_channels(app_id) do
    # We are not matching with the key here, but on another fields.
    # The full table must be scanned. This is ok because this function
    # is not meant to be used by the pubsub server, only from the
    # developer console.
    match = fun do {channel, ^app_id, _} -> channel end
    :ets.select(@table, match)
  end

  def purge_cycle(:millisecond) do
    @cycle_ms
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @server)
  end

  def init([]) do
    schedule_purge()
    tab = :ets.new(@table, [:set, :public, :named_table])
    {:ok, tab}
  end

  def handle_cast({:insert, app_id, channel}, tab) do
    # channels are unique because the app_id is inside the name, 
    # so we use them as keys
    true = :ets.insert(@table, {channel, app_id, now_second() + @ttl_seconds})
    {:noreply, tab}
  end

  def handle_info(:purge, tab) do
    schedule_purge()
    # We use select_delete as if it matches an object, it is expired.
    # if at the same time an new timestamp is
    min = now_second()
    match = fun do {_, _, expire} when expire < ^min -> true end
    Logger.warn("NOT PURGIN CHANNELS @todo")
    # case :ets.select_delete(tab, match) do
    #   0 -> :ok
    #   deleted_count -> Logger.warn("Deleted #{deleted_count} items from the table")
    # end
    {:noreply, tab}
  end

  defp schedule_purge() do
    Process.send_after(self(), :purge, @cycle_ms)
  end

  # using os: since we do not need monotonic time
  defp now_second() do
    :os.system_time(:second)
  end

end