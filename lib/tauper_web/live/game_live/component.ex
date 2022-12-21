defmodule TauperWeb.GameLive.Component do
  use Phoenix.Component

  def periodic_table(assigns) do
    ~H"""
    <div id="table">
    <%=  for atomic_number <- Enum.concat(1..57, 72..88) do %>
        <div class={"element element-#{atomic_number} #{if @question.atomic_number == atomic_number do 'selected' end}"}></div>
    <% end %>
    </div>
    """
  end
end
