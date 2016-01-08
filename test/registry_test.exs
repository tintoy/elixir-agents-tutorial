defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  doctest KV.Registry

  setup do
    {:ok, registry} = KV.Registry.start_link
    {:ok, registry: registry}
  end

  test "can spawn a new bucket", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    bucket = KV.Registry.create(registry, "shopping")
    assert bucket != :error
    
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "removes buckets on exit", %{registry: registry} do
    bucket = KV.Registry.create(registry, "shopping")

    Agent.stop(bucket)
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end
