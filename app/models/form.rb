class Form < ApplicationRecord
  include Scopable

  KINDS = %w[signup petition].freeze
  BUILTIN_FIELDS = {
    "first_name" => "First name",
    "last_name" => "Last name",
    "phone" => "Phone",
    "email" => "Email",
    "zip_code" => "Zip code"
  }.freeze

  belongs_to :apply_tag, class_name: "Tag", optional: true
  has_many :form_fields, -> { order(:position) }, dependent: :destroy
  has_many :submissions, dependent: :destroy

  normalizes :slug, with: ->(value) { value.to_s.parameterize }

  validates :kind, inclusion: { in: KINDS }
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :organization_id }

  before_validation { self.slug = title if slug.blank? }

  def petition? = kind == "petition"

  def signature_count = submissions.count

  # Splits submitted values into person attributes (builtin + custom field
  # keys) for PersonUpsert.
  def person_attributes_from(values)
    attrs = {}
    custom = {}
    custom_keys = organization.custom_fields.pluck(:key)
    form_fields.each do |field|
      value = values[field.key].to_s.strip
      next if value.blank?

      if BUILTIN_FIELDS.key?(field.key)
        attrs[field.key.to_sym] = value
      elsif custom_keys.include?(field.key)
        custom[field.key] = value
      end
    end
    attrs[:custom_field_values] = custom if custom.any?
    attrs
  end

  def submit!(values, source_blast_id: nil)
    person = PersonUpsert.new(organization, person_attributes_from(values)).call
    submission = submissions.create!(person: person, data: values.slice(*form_fields.map(&:key)), source_blast_id: source_blast_id)
    person.taggings.find_or_create_by!(tag: apply_tag) if apply_tag
    Activity.record!(person: person, kind: "form_submitted", subject: submission, data: { "form" => title })
    Workflow.fire(trigger: "form_submitted", person: person, param: slug)
    submission
  end
end
