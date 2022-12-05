defmodule PassaParaulaWeb.WrongLive do
  use Phoenix.LiveView, layout: {PassaParaulaWeb.LayoutView, "live.html"}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       guess_number: :random.uniform(10),
       score: 0,
       message: "Make a guess:",
       time: time()
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Your score: <%= @score %></h1>
    <h2>
    <%= @message %>
    It's <%= @time %>
    </h2>
    <h2>
    <%= for n <- 1..10 do %>
    <a href="#" phx-click="guess" phx-value-number= {n} ><%= n %></a>
    <% end %>
    </h2>
    """
  end

  def time() do
    DateTime.utc_now() |> to_string
  end

  def handle_event("guess", %{"number" => guess} = data, socket) do
    # dbg()
    guess = guess |> String.to_integer
    message =
      if guess == socket.assigns.guess_number do
        "You win!"
      else
        "Your guess: #{guess}. Wrong. Guess again. "
      end

    score = socket.assigns.score - 1

    {
      :noreply,
      assign(
        socket,
        message: message,
        score: score,
        time: time()
      )
    }
  end
end
