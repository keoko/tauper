defmodule LiveButton do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <button phx-click="inc3" phx-target={@myself}
    phx-value-inc3={@inc3} id="b3" type="button" >
      Live Button +<%= @inc3%>, clicked: <%= @int %>
    </button>
    """
  end

  def handle_event("inc3", %{"inc3" => inc3}, socket) do
    socket = update(socket, :int, &(&1 + 1))
    send(self(), %{inc3: inc3})
    {:noreply, socket}
  end
end
