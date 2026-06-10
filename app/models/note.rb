class Note < ApplicationRecord
  belongs_to :person
  belongs_to :user

  validates :body, presence: true

  after_create_commit do
    Activity.record!(person: person, kind: "note_added", subject: self)
  end
end
