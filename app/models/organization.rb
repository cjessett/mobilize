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
  has_many :events, dependent: :destroy
  has_many :forms, dependent: :destroy
  has_many :donations, dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :ledger_entries, dependent: :destroy

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

  # Authenticates inbound webhooks (e.g. donation notifications).
  def webhook_token!
    update!(webhook_token: SecureRandom.hex(16)) if webhook_token.blank?
    webhook_token
  end

  def default_chapter
    chapters.find_by(default: true) || chapters.first
  end

  # Billing is "active" once a Stripe customer exists for the org. Only then
  # do we gate sending on balance and record per-message charges — orgs that
  # have not opted into billing keep working exactly as before.
  def billing_active?
    stripe_customer_id.present?
  end

  # True when billing is active but the prepaid balance is exhausted, so we
  # should stop sending until they add funds.
  def sms_blocked?
    billing_active? && balance_microcents <= 0
  end

  def balance_display
    Money.format(balance_microcents)
  end

  # Atomically applies a ledger entry and updates the cached running balance.
  # amount_microcents is signed (positive credits, negative charges).
  def record_ledger_entry!(entry_type:, amount_microcents:, message: nil, stripe_payment_intent_id: nil, description: nil)
    with_lock do
      new_balance = balance_microcents + amount_microcents
      update!(balance_microcents: new_balance)
      ledger_entries.create!(
        entry_type: entry_type,
        amount_microcents: amount_microcents,
        balance_after_microcents: new_balance,
        message: message,
        stripe_payment_intent_id: stripe_payment_intent_id,
        description: description
      )
    end
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
