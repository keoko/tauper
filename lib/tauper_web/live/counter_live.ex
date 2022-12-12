defmodule TauperWeb.CounterLive do
  use Phoenix.LiveView
  alias TauperWeb.Presence

  def render(assigns) do
    ~L"""
    Current count: <%= @count %>
    <button phx-click="dec">-</button>
    <button phx-click="inc">+</button>
    """
  end

  # def mount(_params, _session, socket) do
  #   topic = "room:lobby"
  #   # before subscribing, let's get the current_reader_count
  #   initial_count = Presence.list(topic) |> map_size

  #   # Subscribe to the topic
  #   TauperWeb.Endpoint.subscribe(topic)

  #   # Track changes to the topic
  #   Presence.track(
  #     self(),
  #     topic,
  #     socket.id,
  #     %{}
  #   )

  #   {:ok, assign(socket, count: initial_count)}
  # end

  # def mount(_params, _session, socket) do
  #   {:ok, assign(socket, count: "123")}
  # end

  def mount(_params, %{"game_code" => game_code}, socket) do
    # def mount(%{"game_code" => game_code}, socket) do
    topic = "game:#{game_code}"
    IO.puts("topic:#{inspect(game_code)}")
    # before subscribing, let's get the current_reader_count
    initial_count = Presence.list(topic) |> map_size

    # Subscribe to the topic
    TauperWeb.Endpoint.subscribe(topic)

    # Track changes to the topic
    Presence.track(
      self(),
      topic,
      socket.id,
      %{}
    )

    {:ok, assign(socket, count: initial_count)}
  end

  # def mount(%{"count" => initial}, socket) do
  #   {:ok, assign(socket, count: initial)}
  # end

  def handle_event("dec", _value, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("inc", _value, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{count: count}} = socket
      ) do
    reader_count = count + map_size(joins) - map_size(leaves)

    {:noreply, assign(socket, count: reader_count)}
  end
end
