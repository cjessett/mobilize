class EmailBlast < ApplicationRecord
  include Scopable

  STATUSES = %w[draft scheduled sending sent failed canceled].freeze

  belongs_to :segment, optional: true
  has_many :email_deliveries, dependent: :destroy
  has_rich_text :body

  validates :name, :subject, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate { errors.add(:body, "can't be blank") if body.blank? }

  def recipients
    base = segment ? segment.people : organization.people
    base = base.where(id: ChapterMembership.where(chapter_id: access_scope_id).select(:person_id)) if access_scope.is_a?(Chapter)
    base.where.not(email: nil).where(unsubscribed_email_at: nil)
  end

  def schedule!(at: Time.current)
    update!(status: "scheduled", scheduled_at: at)
    EmailBlast::SendJob.set(wait_until: at).perform_later(self)
  end

  def cancel!
    update!(status: "canceled") if status == "scheduled"
  end

  def stats
    counts = email_deliveries.group(:status).count
    counts["opened"] = email_deliveries.where.not(opened_at: nil).count
    counts
  end

  def draft? = status == "draft"
  def scheduled? = status == "scheduled"
  def editable? = %w[draft scheduled canceled].include?(status)
end
