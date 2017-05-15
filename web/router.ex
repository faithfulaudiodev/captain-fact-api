defmodule CaptainFact.Router do
  use CaptainFact.Web, :router
  use ExAdmin.Router

  # ---- Pipelines ----

  # Browser (backadmin)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :browser_auth do
    plug Guardian.Plug.EnsureAuthenticated
    plug CaptainFact.Plugs.SuperAdmin
  end

  # API

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  # ---- Routes ----

  # Browser (backadmin)

  scope "/admin", CaptainFact do
    pipe_through :browser
    get "/login", UserController, :admin_login
    delete "/logout", UserController, :admin_logout
  end

  scope "/admin", ExAdmin do
    pipe_through [:browser, :browser_auth]
    admin_routes()
  end

  # API

  scope "/api", CaptainFact do
    pipe_through [:api, :api_auth]

    # Authentication
    scope "/auth" do
      get "/me", AuthController, :me
      get "/:provider", AuthController, :request
      post "/:identity/callback", AuthController, :callback
      delete "/signout", AuthController, :delete
    end

    # Users
    post "/users", UserController, :create
    put "/users/:user_id", UserController, :update
    get "/users/:username", UserController, :show
    get "/users/:user_id/videos", VideoController, :index

    # Videos
    get "/videos", VideoController, :index
    post "/videos", VideoController, :get_or_create

    # Subscribe to the newsletter
    post "/newsletter/subscribe", UserController, :newsletter_subscribe
  end

  scope "/extension_api", CaptainFact do
    pipe_through [:api, :api_auth]

    # Statements
    get "/videos/:video_id/statements", StatementController, :get
    post "/search/video", VideoController, :search
  end
end
