class FormField < ApplicationRecord
  belongs_to :form

  validates :key, :label, presence: true
  validates :key, uniqueness: { scope: :form_id }
end
