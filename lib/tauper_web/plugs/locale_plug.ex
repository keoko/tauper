defmodule TauperWeb.Plugs.Locale do
  alias Plug.Conn

  @locales Gettext.known_locales(TauperWeb.Gettext)

  # 10 days
  @cookie_max_age 10 * 24 * 60 * 60

  def init(_opts), do: nil

  # def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _opts) when locale in @locales do
  def call(conn, _opts) do
    locale =
      case locale_from_params(conn) || locale_from_cookies(conn) do
        nil ->
          Gettext.get_locale(TauperWeb.Gettext)

        locale ->
          locale
      end

    Gettext.put_locale(TauperWeb.Gettext, locale)

    conn
    |> Conn.put_resp_cookie("locale", locale, max_age: @cookie_max_age)
    |> Conn.put_session(:locale, locale)
  end

  defp locale_from_params(conn) do
    conn.params["locale"] |> validate_locale
  end

  defp locale_from_cookies(conn) do
    conn.cookies["locale"] |> validate_locale
  end

  defp validate_locale(locale) when locale in @locales, do: locale
  defp validate_locale(_locale), do: nil
end
