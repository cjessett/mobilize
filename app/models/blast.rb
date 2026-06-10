class Blast < ApplicationRecord
  include Scopable

  STATUSES = %w[draft scheduled sending sent failed canceled].freeze

  belongs_to :segment, optional: true
  has_many :messages, dependent: :nullify

  validates :name, :body, presence: true
  validates :status, inclusion: { in: STATUSES }

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

  def draft? = status == "draft"
  def scheduled? = status == "scheduled"
  def editable? = %w[draft scheduled canceled].include?(status)
end
