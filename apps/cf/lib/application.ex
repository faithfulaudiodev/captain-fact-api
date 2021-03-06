defmodule CF.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Other custom supervisors
      supervisor(CF.Sources.Fetcher, []),
      # Misc workers
      worker(CF.Accounts.UsernameGenerator, []),
      # Sweep tokens from db
      worker(Guardian.DB.Token.SweeperServer, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CF.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def version() do
    case :application.get_key(:cf, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end

  @doc """
  If Mix is available, returns Mix.env(). If not available (in releases) return :prod
  """
  @deprecated "use Application.get_env(:cf, :env)"
  def env() do
    (Kernel.function_exported?(Mix, :env, 0) && Mix.env()) || :prod
  end
end
