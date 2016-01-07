defmodule KV.Bucket do
  @doc """
  Start a new bucket (key / value pair storage).
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

  @doc """
  Remove the specified `key` (and its corresponding `value`) from the bucket, returning the `value` if present.
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn dict ->
      Map.pop(dict, key)
    end)
  end
end
