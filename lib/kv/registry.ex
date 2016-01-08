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
    GenServer.cast(server, {:create, name})
  end

  ## Server callbacks

  def init(:ok) do
    bucket_names = %{}
    monitor_refs = %{}

    {:ok, {bucket_names, monitor_refs}}
  end

  # My best guess (reading the docs would be cheating) is that these handle_xxx methods take:
  # * A message (in this case a tuple)
  # * The sender's PID
  # * The current server state data (which is probably passed this way because Elixir doesn't do classes).
  # They then return a tuple containing:
  # * The resulting server command (reply, no reply, etc)
  # * The command's associated parameters (if any)
  # * The new server state data.

  # Handle a synchronous call to the server (*must* reply to caller).
  def handle_call({:lookup, name}, _from, {bucket_names, _} = state) do
    {
      :reply, # Resulting command (send reply to caller)
      Map.fetch(bucket_names, name), # Resulting command parameter (data to send to caller)
      state # Same server state data
    }
  end

  # Handle an asynchronous call to the server (*cannot* reply to the caller, because we don't know who that is).
  def handle_cast({:create, name}, {bucket_names, monitor_refs}) do
    if Map.has_key?(bucket_names, name) do
      {
        :noreply, # Resulting command (don't reply to caller)
        {bucket_names, monitor_refs} # Same server state data
      }
    else
      {:ok, bucket} = KV.Bucket.start_link
      bucket_names = Map.put(bucket_names, name, bucket)

      monitor_ref = Process.monitor(bucket) # We'll want to remove this bucket from the registry when it stops.
      monitor_refs = Map.put(monitor_refs, monitor_ref, name)

      {
        :noreply, # Resulting command (don't reply to caller)
        {bucket_names, monitor_refs} # New server state data
      }
    end
  end

  # Handle notification of bucket shutdown
  def handle_info({:DOWN, monitor_ref, :process, _pid, _reason}, {bucket_names, monitor_refs}) do
    {bucket_name, monitor_refs} = Map.pop(monitor_refs, monitor_ref)
    bucket_names = Map.delete(bucket_names, bucket_name)

    {
      :noreply, # Resulting command (don't reply to caller)
      {bucket_names, monitor_refs} # New server state data
    }
  end

  # Catch-all (ignore any other type of message)
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
