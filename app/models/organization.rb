class Organization < ApplicationRecord
  belongs_to :parent, class_name: "Organization", optional: true
  has_many :sub_organizations, class_name: "Organization", foreign_key: :parent_id, dependent: :destroy
  has_many :chapters, dependent: :destroy
  has_many :people, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :custom_fields, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :segments, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :blasts, dependent: :destroy
  has_many :sms_templates, dependent: :destroy
  has_many :keywords, dependent: :destroy
  has_many :email_blasts, dependent: :destroy
  has_many :workflows, dependent: :destroy

  def chapter_for_phone_number(number)
    chapters.find_by(phone_number: PhoneNumber.normalize(number))
  end

  def self.for_inbound_number(number)
    Chapter.find_by(phone_number: PhoneNumber.normalize(number))&.organization
  end

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.name } + ActiveSupport::TimeZone.all.map(&:name) }

  before_validation :generate_slug, on: :create

  def default_chapter
    chapters.find_by(default: true) || chapters.first
  end

  def chapter_for_zip(zip_code)
    return nil if zip_code.blank?

    chapters.joins(:chapter_zip_codes).find_by(chapter_zip_codes: { zip_code: zip_code.to_s.strip[0, 5] })
  end

  private

  def generate_slug
    self.slug ||= name.to_s.parameterize.presence
  end
end
