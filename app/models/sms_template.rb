class SmsTemplate < ApplicationRecord
  belongs_to :organization

  validates :name, :body, presence: true
end
