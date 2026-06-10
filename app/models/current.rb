class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :membership
  delegate :user, to: :session, allow_nil: true
  delegate :organization, to: :membership, allow_nil: true
end
