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
    {:ok, %{}}
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
  def handle_call({:lookup, name}, _from, names) do
     {
       :reply, # Resulting command (send reply to caller)
       Map.fetch(names, name), # Resulting command parameter (data to send to caller)
       names # New server state data
     }
  end

  # Handle an asynchronous call to the server (*cannot* reply to the caller, because we don't know who that is).
  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {
        :noreply, # Resulting command (don't reply to caller)
        names # New server state data
      }
    else
      {:ok, bucket} = KV.Bucket.start_link

      {
        :noreply, # Resulting command (don't reply to caller)
        Map.put(names, name, bucket) # New server state data
      }
    end
  end
end
