defmodule KV.Registry do
  use GenServer

  ## Client API

  @doc """
  Start a new instance of the registry
  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Stop the registry `server`.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  @doc """
  Look up the PID of the bucket with the specified `name` in the specified `server`.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensure there is a bucket with the specified `name` in the specified `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Server callbacks

  def init(:ok) do
    buckets_by_name = %{}
    names_by_monitor_ref = %{}

    {:ok, {buckets_by_name, names_by_monitor_ref}}
  end

  # My best guess (reading the docs would be cheating) is that these handle_xxx methods take:
  # * A message (in this case a tuple)
  # * The sender's PID
  # * The current server state data (which is probably passed this way because Elixir doesn't do classes).
  # They then return a tuple containing:
  # * The resulting server command (reply, no reply, etc)
  # * The command's associated parameters (if any)
  # * The new server state data.

  # Handle bucket lookup
  def handle_call({:lookup, name}, _from, {buckets_by_name, _} = state) do
    {
      :reply, # Resulting command (send reply to caller)
      Map.fetch(buckets_by_name, name), # Resulting command parameter (data to send to caller)
      state # Same server state data
    }
  end

  # Handle bucket creation
  def handle_call({:create, name}, _from, {buckets_by_name, names_by_monitor_ref}) do
    if Map.has_key?(buckets_by_name, name) do
      {
        :reply, # Resulting command (reply to caller)
        Map.get(buckets_by_name, name), # Resulting command parameter (data to send to caller)
        {buckets_by_name, names_by_monitor_ref} # Same server state data
      }
    else
      {:ok, bucket} = KV.Bucket.start_link
      buckets_by_name = Map.put(buckets_by_name, name, bucket)

      monitor_ref = Process.monitor(bucket) # We'll want to remove this bucket from the registry when it stops.
      names_by_monitor_ref = Map.put(names_by_monitor_ref, monitor_ref, name)

      {
        :reply, # Resulting command (reply to caller)
        bucket,# Resulting command parameter (data to send to caller)
        {buckets_by_name, names_by_monitor_ref} # New server state data
      }
    end
  end

  # Handle notification of bucket shutdown
  def handle_info({:DOWN, monitor_ref, :process, _pid, _reason}, {buckets_by_name, names_by_monitor_ref}) do
    {bucket_name, names_by_monitor_ref} = Map.pop(names_by_monitor_ref, monitor_ref)
    buckets_by_name = Map.delete(buckets_by_name, bucket_name)

    {
      :noreply, # Resulting command (don't reply to caller)
      {buckets_by_name, names_by_monitor_ref} # New server state data
    }
  end

  # Catch-all (ignore any other type of message)
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
