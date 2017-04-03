defmodule CaptainFact.Router do
  use CaptainFact.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  scope "/", CaptainFact do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api", CaptainFact do
    pipe_through [:api, :api_auth]

    post "/users", UserController, :create
    get "/users/", UserController, :show
    get "/users/search/:query_string", UserController, :search
    get "/users/:username", UserController, :show
    get "/users/:user_id/videos", VideoController, :index

    resources "/videos", VideoController, only: [:index, :create, :update, :delete]
  end

  scope "/api/auth", CaptainFact do
    pipe_through [:api, :api_auth]

    get "/me", AuthController, :me
    get "/:provider", AuthController, :request
    post "/:identity/callback", AuthController, :callback
    delete "/signout", AuthController, :delete
  end
end
