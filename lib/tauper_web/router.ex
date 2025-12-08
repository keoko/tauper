defmodule TauperWeb.Router do
  use TauperWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TauperWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug TauperWeb.Plugs.Locale
    plug TauperWeb.Plugs.SessionToAssignPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TauperWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/multiplayer", PageController, :multiplayer

    resources "/games", GameController, only: [:index, :new, :create]
    get "/games/join", GameController, :new_join
    post "/games/join", GameController, :join
    get "/games/rejoin", GameController, :rejoin

    live_session :show, on_mount: TauperWeb.GameLive.Show do
      live "/games/:code", GameLive.Show, :show
    end

    live_session :default, on_mount: TauperWeb.GameLive.Play do
      live "/games/play/:code", GameLive.Play, :play
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TauperWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TauperWeb.Telemetry
    end
  end

end
