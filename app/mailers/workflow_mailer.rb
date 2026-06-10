class WorkflowMailer < ApplicationMailer
  def step_email(person, subject, body)
    @person = person
    @body = MergeTags.render(body, person)
    @unsubscribe_url = unsubscribe_url(token: person.generate_token_for(:unsubscribe))
    mail(to: person.email, subject: MergeTags.render(subject, person), from: ENV.fetch("MAIL_FROM", "no-reply@mobilize.test"))
  end

  def member_notification(user, workflow, person)
    @workflow = workflow
    @person = person
    mail(to: user.email_address, subject: "[Mobilize] Workflow \"#{workflow.name}\" matched #{person.name}", from: ENV.fetch("MAIL_FROM", "no-reply@mobilize.test"))
  end
end
