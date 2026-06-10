class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :person

  validates :tag_id, uniqueness: { scope: :person_id }

  after_create_commit do
    Workflow.fire(trigger: "tag_added", person: person, param: tag.name)
  end
end
