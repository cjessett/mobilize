class Donation < ApplicationRecord
  belongs_to :organization
  belongs_to :person

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :donated_at, presence: true

  before_validation { self.donated_at ||= Time.current }

  after_create_commit :record_activity, :fire_workflows

  def amount
    amount_cents / 100.0
  end

  private

  def record_activity
    Activity.record!(person: person, kind: "donation_created", subject: self, data: { amount_cents: amount_cents, source: source }, occurred_at: donated_at)
  end

  def fire_workflows
    Workflow.fire(trigger: "donation_created", person: person, param: source)
  end
end
