defmodule Tauper.Email.ScoreEmail do
  use Phoenix.Swoosh,
    view: TauperWeb.EmailView

  def send_score_email(email_to, code, podium) do
    email_subject = "Game Score #{code}"

    email =
      new()
      |> from({"Natxo Cabré", "natxo.cabre@gmail.com"})
      |> to({email_to, email_to})
      |> subject(email_subject)
      |> render_body("score_email.html", %{podium: podium})

    Tauper.Mailer.deliver(email)
  end
end
