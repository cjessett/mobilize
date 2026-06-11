require "net/http"

class Workflow::WebhookJob < ApplicationJob
  queue_as :default

  def perform(workflow, person, url)
    uri = URI.parse(url)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?

    payload = {
      workflow: { id: workflow.id, name: workflow.name },
      person: {
        id: person.id, first_name: person.first_name, last_name: person.last_name,
        phone: person.phone, email: person.email
      },
      fired_at: Time.current.iso8601
    }
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.post(uri.request_uri.presence || "/", payload.to_json, "Content-Type" => "application/json")
    end
  end
end
