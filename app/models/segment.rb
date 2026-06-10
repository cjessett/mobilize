# A saved filter over People. `definition` shape:
#   { "match" => "all" | "any",
#     "conditions" => [
#       { "type" => "field", "field" => "zip_code", "op" => "eq|contains|present|blank", "value" => "60601" },
#       { "type" => "custom_field", "key" => "union_member", "op" => "eq|contains|present|blank", "value" => "yes" },
#       { "type" => "tag", "op" => "has|not_has", "tag_id" => 1 },
#       { "type" => "chapter", "chapter_id" => 2 }
#     ] }
class Segment < ApplicationRecord
  include Scopable

  ALLOWED_FIELDS = %w[first_name last_name phone email city state zip_code preferred_language].freeze

  validates :name, presence: true
  validate :definition_is_valid

  def conditions
    Array(definition["conditions"])
  end

  def match_any? = definition["match"] == "any"

  def people
    base = organization.people
    relations = conditions.filter_map { |condition| relation_for(base, condition) }
    return base if relations.empty?

    relations.reduce { |a, b| match_any? ? a.or(b) : a.merge(b) }
  end

  private

  def relation_for(base, condition)
    case condition["type"]
    when "field" then field_relation(base, condition["field"], condition["op"], condition["value"])
    when "custom_field" then custom_field_relation(base, condition["key"], condition["op"], condition["value"])
    when "tag" then tag_relation(base, condition["op"], condition["tag_id"])
    when "chapter" then base.where(id: ChapterMembership.where(chapter_id: condition["chapter_id"]).select(:person_id))
    end
  end

  def field_relation(base, field, op, value)
    return nil unless ALLOWED_FIELDS.include?(field)

    column = Person.arel_table[field]
    case op
    when "eq" then base.where(field => value)
    when "contains" then base.where(column.matches("%#{ActiveRecord::Base.sanitize_sql_like(value.to_s)}%"))
    when "present" then base.where.not(field => [ nil, "" ])
    when "blank" then base.where(field => [ nil, "" ])
    end
  end

  def custom_field_relation(base, key, op, value)
    path = "$.#{key}"
    case op
    when "eq" then base.where("json_extract(custom_field_values, ?) = ?", path, value.to_s)
    when "contains" then base.where("json_extract(custom_field_values, ?) LIKE ?", path, "%#{ActiveRecord::Base.sanitize_sql_like(value.to_s)}%")
    when "present" then base.where("json_extract(custom_field_values, ?) IS NOT NULL AND json_extract(custom_field_values, ?) != ''", path, path)
    when "blank" then base.where("json_extract(custom_field_values, ?) IS NULL OR json_extract(custom_field_values, ?) = ''", path, path)
    end
  end

  def tag_relation(base, op, tag_id)
    tagged = Tagging.where(tag_id: tag_id).select(:person_id)
    op == "not_has" ? base.where.not(id: tagged) : base.where(id: tagged)
  end

  def definition_is_valid
    unless definition.is_a?(Hash) && conditions.all? { |c| c.is_a?(Hash) && c["type"].present? }
      errors.add(:definition, "is invalid")
    end
  end
end
