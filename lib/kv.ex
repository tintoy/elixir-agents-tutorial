defmodule KV do
  use Application

  @doc """
  Start the application.
  """
  def start(_type, _args) do
    KV.Supervisor.start_link
  end
end
