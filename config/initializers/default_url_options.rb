# Host for URLs generated outside a request (MMS media URLs, short links,
# Twilio status callbacks). Set APP_HOST in production, e.g. "app.example.org".
host = ENV["APP_HOST"].presence
host ||= "www.example.com" if Rails.env.test? # matches the integration test host
host ||= "localhost:3000" unless Rails.env.production?
Rails.application.routes.default_url_options[:host] = host if host
