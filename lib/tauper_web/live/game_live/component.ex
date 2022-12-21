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

  def players(assigns) do
    ~H"""
    <div id="players">
     <strong>Players:</strong>
    <%= if Enum.count(@players) == 0 do %>
    <p>No players yet.</p>
    <% else %>
     <ul>
     <%= for player <- @players do %>
         <li><%= player.name %> </li>
     <% end %>
     </ul>
    <% end %>
    </div>
    """
  end

  def podium(assigns) do
    ~H"""
    <%= if @podium do %>
     <h2><%= @title %></h2>
     <table>
       <thead>
         <tr>
           <th>Position</th>
           <th>Player</th>
           <th>Score</th>
         </tr>
       </thead>
       <tbody>
     <%= for {{player_name, score}, position} <- Enum.with_index(@podium, 1) do %>
       <tr>
         <td><%= position %></td>
         <td><%= player_name %></td>
         <td><%= score %> points</td>
       </tr>
     <% end %>
       </tbody>
     </table>
    <% end %>
    """
  end
end
