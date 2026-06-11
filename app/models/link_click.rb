class LinkClick < ApplicationRecord
  belongs_to :short_link

  validates :clicked_at, presence: true
end
