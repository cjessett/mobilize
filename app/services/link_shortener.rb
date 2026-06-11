# Rewrites URLs in an outbound SMS body to app-hosted short links so clicks
# can be tracked per recipient. Links to this app's own pages get an `mb`
# param so form submissions can be attributed back to the blast.
class LinkShortener
  URL_PATTERN = %r{https?://[^\s<>"')\]]+}

  def self.rewrite(body, organization:, blast: nil, message: nil, person: nil)
    return body if app_host.blank?

    body.to_s.gsub(URL_PATTERN) do |url|
      next url if own_host?(url) && url.include?("/l/") # already shortened

      link = ShortLink.create!(
        organization: organization,
        blast: blast,
        message: message,
        person: person,
        destination_url: attributed_destination(url, blast)
      )
      link.short_url
    end
  end

  def self.attributed_destination(url, blast)
    return url unless blast && own_host?(url)

    separator = URI.parse(url).query.present? ? "&" : "?"
    "#{url}#{separator}mb=#{blast.id}"
  rescue URI::InvalidURIError
    url
  end

  def self.own_host?(url)
    URI.parse(url).host == app_host.to_s.split(":").first
  rescue URI::InvalidURIError
    false
  end

  def self.app_host
    Rails.application.routes.default_url_options[:host]
  end
end
