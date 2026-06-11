class ShortLinksController < ApplicationController
  allow_unauthenticated_access

  def show
    link = ShortLink.find_by!(token: params[:token])
    link.link_clicks.create!(clicked_at: Time.current, user_agent: request.user_agent, ip: request.remote_ip)
    if link.person
      Activity.record!(person: link.person, kind: "link_clicked", subject: link, data: { "url" => link.destination_url })
      Workflow.fire(trigger: "link_clicked", person: link.person, param: link.blast_id)
    end
    redirect_to link.destination_url, allow_other_host: true
  end
end
