# Per-language overrides stored in a `variants` JSON column, e.g.
# { "es" => { "body" => "Hola {{first_name}}" } }. The model's own columns
# are the default language; missing variants fall back to them.
module LanguageVariants
  extend ActiveSupport::Concern

  LANGUAGES = {
    "es" => "Spanish",
    "zh" => "Chinese",
    "vi" => "Vietnamese",
    "ko" => "Korean",
    "tl" => "Tagalog",
    "fr" => "French",
    "ar" => "Arabic"
  }.freeze

  # Resolves a person's free-text preferred_language ("es", "Spanish") to a
  # variant key.
  def self.language_key(value)
    normalized = value.to_s.strip.downcase
    return nil if normalized.blank?
    return normalized if LANGUAGES.key?(normalized)

    LANGUAGES.find { |_code, name| name.downcase == normalized }&.first
  end

  def body_for(language)
    variant_for(language)&.dig("body").presence || self[:body]
  end

  def subject_for(language)
    variant_for(language)&.dig("subject").presence || self[:subject]
  end

  def variant_for(language)
    key = LanguageVariants.language_key(language)
    key && variants.is_a?(Hash) ? variants[key] : nil
  end

  # Drops languages where every field is blank so empty form inputs don't
  # accumulate.
  def variants=(value)
    hash = value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value.to_h
    cleaned = hash.each_with_object({}) do |(lang, fields), acc|
      fields = fields.to_h.transform_values(&:to_s)
      acc[lang.to_s] = fields if fields.values.any?(&:present?)
    end
    super(cleaned)
  end
end
