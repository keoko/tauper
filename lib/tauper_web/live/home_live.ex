defmodule TauperWeb.HomeLive do
  use Phoenix.LiveView

  def mount(_, _, socket) do
    {:ok, assign(socket, count: 0)}
  end

  # def render(assigns) do
  #   ~H"""
  #     <button id="b1"  phx-click="inc1" phx-value-inc1={1} type="button">
  #       Increment: +1
  #     </button>
  #     <p>Counter: <%= @count %></p>
  #   """
  # end

  # def render(assigns) do
  #   ~H"""
  #     <SimpleCounter.display inc2={10}/>
  #     <p>Counter: <%= @count %></p>
  #   """
  # end

  def render(assigns) do
    ~H"""
      <.live_component module={LiveButton} inc3={100} int={0} id="b3" />
      <p>Counter: <%= @count %></p>
    """
  end

  def handle_event("inc1", %{"inc1" => inc1}, socket) do
    {:noreply, socket |> update(:count, &(&1 + String.to_integer(inc1)))}
  end

  def handle_event("inc2", %{"inc2" => inc2}, socket) do
    inc2 = String.to_integer(inc2)
    {:noreply, socket |> update(:count, &(&1 + inc2))}
  end

  def handle_info(%{inc3: inc3}, socket) do
    inc3 = String.to_integer(inc3)

    socket =
      socket
      |> update(:count, &(&1 + inc3))
      |> update(:clicks, &Map.put(&1, :b3, &1.b3 + 1))

    {:noreply, socket}
  end
end
