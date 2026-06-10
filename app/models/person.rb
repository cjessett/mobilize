class Person < ApplicationRecord
  belongs_to :organization
  has_one :user, dependent: :nullify
  has_many :chapter_memberships, dependent: :destroy
  has_many :chapters, through: :chapter_memberships

  normalizes :phone, with: ->(value) { PhoneNumber.normalize(value) }
  normalizes :email, with: ->(value) { value.strip.downcase.presence }
  normalizes :zip_code, with: ->(value) { value.to_s.strip[0, 5].presence }

  validates :phone, uniqueness: { scope: :organization_id }, allow_nil: true
  validates :phone, format: { with: /\A\+\d{11,15}\z/, message: "must be a valid phone number" }, allow_nil: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validate :phone_or_email_present

  after_create :assign_primary_chapter

  def name
    [ first_name, last_name ].compact_blank.join(" ").presence || phone || email
  end

  def primary_chapter
    chapters.merge(ChapterMembership.where(primary: true)).first || organization.default_chapter
  end

  def assign_primary_chapter(chapter: nil)
    chapter ||= organization.chapter_for_zip(zip_code) || organization.default_chapter
    return if chapter.nil?

    transaction do
      chapter_memberships.where(primary: true).where.not(chapter: chapter).update_all(primary: false)
      membership = chapter_memberships.find_or_initialize_by(chapter: chapter)
      membership.update!(primary: true)
    end
  end

  def opted_out_sms? = opted_out_sms_at.present?
  def unsubscribed_email? = unsubscribed_email_at.present?

  private

  def phone_or_email_present
    errors.add(:base, "Phone or email is required") if phone.blank? && email.blank?
  end
end
