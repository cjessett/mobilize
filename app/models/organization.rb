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

  # Whether the chapter-billing + provisioning feature is turned on for this
  # org (LaunchDarkly flag). When off, the org behaves exactly as before.
  def billing_feature_enabled?
    FeatureFlags.enabled?(FeatureFlags::CHAPTER_BILLING, self)
  end

  # Billing is "active" once a Stripe customer exists for the org. Only then
  # do we gate sending on balance and record per-message charges — orgs that
  # have not opted into billing keep working exactly as before.
  def billing_active?
    stripe_customer_id.present?
  end

  # Messages are metered/charged only when the feature is on AND the org has
  # opted into billing.
  def sms_billable?
    billing_feature_enabled? && billing_active?
  end

  # Funds available to spend: balance minus the amount reserved by in-flight
  # messages (pre-auth holds).
  def available_microcents
    balance_microcents - held_microcents
  end

  def balance_display
    Money.format(balance_microcents)
  end

  def available_display
    Money.format(available_microcents)
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

  # Reserves an estimated amount against the available balance before sending.
  # Returns true if the hold was placed, false if there aren't enough funds.
  def reserve_sms_hold!(amount_microcents, message:)
    with_lock do
      return false if available_microcents < amount_microcents

      update!(held_microcents: held_microcents + amount_microcents)
      message.update!(hold_microcents: amount_microcents)
      true
    end
  end

  # Releases a message's hold without charging (e.g. the send failed).
  def release_sms_hold!(message)
    return if message.hold_microcents.blank?

    with_lock do
      update!(held_microcents: [ held_microcents - message.hold_microcents, 0 ].max)
      message.update!(hold_microcents: nil)
    end
  end

  # Settles a delivered message: releases its hold and debits the real cost,
  # writing a single charge ledger entry. Atomic and idempotent (the caller
  # guards on message.cost_microcents).
  def settle_sms_charge!(message:, amount_microcents:)
    with_lock do
      released = message.hold_microcents.to_i
      new_held = [ held_microcents - released, 0 ].max
      new_balance = balance_microcents - amount_microcents
      update!(held_microcents: new_held, balance_microcents: new_balance)
      ledger_entries.create!(
        entry_type: "charge",
        amount_microcents: -amount_microcents,
        balance_after_microcents: new_balance,
        message: message,
        description: "SMS to #{message.person.phone}"
      )
    end
  end

  # Admin-granted credits (e.g. an org paid by cash). Bypasses Stripe.
  def grant_credits!(amount_microcents:, description: nil)
    raise ArgumentError, "Grant amount must be positive" unless amount_microcents.to_i.positive?

    record_ledger_entry!(entry_type: "grant", amount_microcents: amount_microcents, description: description || "Credit grant")
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
