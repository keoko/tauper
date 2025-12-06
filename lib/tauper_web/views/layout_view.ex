defmodule TauperWeb.LayoutView do
  use TauperWeb, :view
  alias TauperWeb.Router.Helpers, as: Routes

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def switch_locale_path(conn, locale, language) do
    "<a href=\"#{Routes.page_path(conn, :index, locale: locale)}\">#{language}</a>" |> raw
  end
end
