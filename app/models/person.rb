class Person < ApplicationRecord
  belongs_to :organization
  has_one :user, dependent: :nullify
  has_many :chapter_memberships, dependent: :destroy
  has_many :chapters, through: :chapter_memberships
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :notes, dependent: :destroy
  has_many :activities, dependent: :destroy

  scope :visible_to, ->(membership) {
    scope = where(organization: membership.organization)
    if membership.org_wide?
      scope
    else
      scope.where(id: ChapterMembership.where(chapter: membership.accessible_chapters).select(:person_id))
    end
  }

  scope :search, ->(query) {
    next all if query.blank?

    term = "%#{sanitize_sql_like(query.strip)}%"
    where("first_name LIKE :t OR last_name LIKE :t OR phone LIKE :t OR email LIKE :t", t: term)
  }

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

  def tag_list
    tags.order(:name).pluck(:name).join(", ")
  end

  def tag_list=(names)
    names = names.split(",") if names.is_a?(String)
    @pending_tag_names = names.map { |n| n.to_s.strip }.reject(&:blank?).uniq
  end

  after_save :sync_tags

  def opted_out_sms? = opted_out_sms_at.present?
  def unsubscribed_email? = unsubscribed_email_at.present?

  private

  def sync_tags
    return if @pending_tag_names.nil?

    desired = @pending_tag_names.map { |name| organization.tags.find_or_create_by!(name: name) }
    taggings.where.not(tag_id: desired.map(&:id)).destroy_all
    desired.each { |tag| taggings.find_or_create_by!(tag: tag) }
    @pending_tag_names = nil
  end

  def phone_or_email_present
    errors.add(:base, "Phone or email is required") if phone.blank? && email.blank?
  end
end
