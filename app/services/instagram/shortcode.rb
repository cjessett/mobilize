module Instagram
  module Shortcode
    # Standard base64url alphabet Instagram uses to encode media IDs as shortcodes.
    ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

    def self.to_id(shortcode)
      n = 0
      shortcode.each_char { |c| n = (n << 6) + ALPHABET.index(c).to_i }
      n.to_s
    end

    def self.from_url(url)
      url.to_s.match(%r{instagram\.com/(?:p|reel|tv)/([^/?#]+)})&.captures&.first
    end

    def self.to_url(shortcode)
      "https://www.instagram.com/p/#{shortcode}/"
    end
  end
end
