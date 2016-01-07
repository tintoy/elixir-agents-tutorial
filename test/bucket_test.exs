defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  test "can store and retrieve a value by key" do
    {:ok, bucket} = KV.Bucket.start_link
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "can remove a value by key" do
    {:ok, bucket} = KV.Bucket.start_link
    assert KV.Bucket.delete(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.delete(bucket, "milk") == 3

    # Should be gone now.
    assert KV.Bucket.delete(bucket, "milk") == nil
  end
end
