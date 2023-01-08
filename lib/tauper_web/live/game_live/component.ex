defmodule TauperWeb.GameLive.Component do
  use Phoenix.Component
  use Phoenix.HTML

  import TauperWeb.ErrorHelpers
  import TauperWeb.Gettext

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
     <section id="players">
      <header><h3><%= gettext("Players") %></h3></header>

    <%= if Enum.count(@players) == 0 do %>
    <p><%= gettext("No players yet") %></p>
    <% else %>
     <ul>
     <%= for player <- @players do %>
         <li><%= player.name %> </li>
     <% end %>
     </ul>
    <% end %>
    </section>
    """
  end

  def podium(assigns) do
    ~H"""
    <%= if @podium do %>
     <section id="players">
      <header><h3><%= @title %></h3></header>
      <table id="podium">
       <thead>
         <tr>
           <th><%= gettext("Position") %></th>
           <th><%= gettext("Player") %></th>
           <th><%= gettext("Score") %></th>
         </tr>
       </thead>
       <tbody>
     <%= for {{player_name, score}, position} <- Enum.with_index(@podium, 1) do %>
       <tr>
         <td class="position"><%= position %></td>
         <td class="player_name"><%= player_name %></td>
         <td class="score"><%= score %> <%= gettext("points") %></td>
       </tr>
     <% end %>
       </tbody>
     </table>
     </section>
    <% end %>
    """
  end

  def question_form(assigns) do
    ~H"""
    <div>
        <.form
        let={f}
        for={@changeset}
        id="answer-form"
        as="answer-form"
        phx-submit="answer">
        <%= text_input f, :answer, autocomplete: "off", autofocus: "true" %>
        <%= error_tag f, :answer %>
        <%= submit gettext("send answer"), phx_disable_with: gettext("Sending answer...") %>
        </.form>
    </div>
    """
  end

  def sentence(assigns) do
    ~H"""
    <main id="sentence">
        (<%= @game.current_question + 1 %>/<%=  @game.num_questions %>) <strong><%= @question.sentence %></strong>
    </main>
    """
  end
end
