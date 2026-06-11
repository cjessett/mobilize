class Blast < ApplicationRecord
  include Scopable
  include LanguageVariants

  STATUSES = %w[draft scheduled sending sent failed canceled].freeze

  MAX_MEDIA = 10
  MAX_MEDIA_BYTES = 5.megabytes
  MEDIA_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  belongs_to :segment, optional: true
  has_many :messages, dependent: :nullify
  has_many :short_links, dependent: :nullify
  has_many_attached :media

  validates :name, :body, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :validate_media

  def recipients
    base = segment ? segment.people : organization.people
    base = base.where(id: ChapterMembership.where(chapter_id: access_scope_id).select(:person_id)) if access_scope.is_a?(Chapter)
    base.where.not(phone: nil).where(opted_out_sms_at: nil)
  end

  def schedule!(at: Time.current)
    update!(status: "scheduled", scheduled_at: at)
    Blast::SendJob.set(wait_until: at).perform_later(self)
  end

  def cancel!
    update!(status: "canceled") if status == "scheduled"
  end

  def stats
    messages.group(:status).count
  end

  def total_clicks
    LinkClick.joins(:short_link).where(short_links: { blast_id: id }).count
  end

  def unique_clickers
    ShortLink.where(blast_id: id).joins(:link_clicks).distinct.count(:person_id)
  end

  def attributed_submissions
    Submission.where(source_blast_id: id).count
  end

  def has_links? = ShortLink.exists?(blast_id: id)

  def draft? = status == "draft"
  def scheduled? = status == "scheduled"
  def editable? = %w[draft scheduled canceled].include?(status)

  private

  def validate_media
    errors.add(:media, "can include at most #{MAX_MEDIA} files") if media.size > MAX_MEDIA
    media.blobs.each do |blob|
      errors.add(:media, "must be images (JPEG, PNG, GIF, or WebP)") unless MEDIA_TYPES.include?(blob.content_type)
      errors.add(:media, "files must be 5MB or smaller") if blob.byte_size > MAX_MEDIA_BYTES
    end
  end
end
