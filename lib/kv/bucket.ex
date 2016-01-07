defmodule KV.Bucket do
  @doc """
  Starts a new bucket (key / value pair storage).
  """
  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Get a `value` from the bucket by its `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Put a `value` into the bucket with the specified `key`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end
end
