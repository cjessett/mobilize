class BlastMailer < ApplicationMailer
  def blast(delivery)
    @delivery = delivery
    @person = delivery.person
    @blast = delivery.email_blast
    @body_html = MergeTags.render(@blast.body.to_s, @person)
    @unsubscribe_url = unsubscribe_url(token: @person.generate_token_for(:unsubscribe))
    @open_url = email_open_url(token: @delivery.generate_token_for(:open_tracking), format: :gif)

    mail(
      to: @person.email,
      subject: MergeTags.render(@blast.subject, @person),
      from: ENV.fetch("MAIL_FROM", "no-reply@mobilize.test")
    )
  end
end
