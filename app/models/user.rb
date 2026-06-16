class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :person, optional: true
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def membership_for(organization)
    memberships.find_by(organization: organization)
  end

  def default_membership
    memberships.order(:created_at).first
  end

  def name
    person&.name || email_address
  end

  # Platform-level operator. Can grant Twilio credits to any org (bypassing
  # Stripe) — distinct from per-org admin roles.
  def superadmin? = superadmin
end
