# Renders {{tag}} placeholders in message bodies. Supported tags:
# first_name, last_name, name, chapter_name, plus any custom field key.
module MergeTags
  def self.render(body, person)
    body.to_s.gsub(/\{\{\s*(\w+)\s*\}\}/) do
      key = Regexp.last_match(1)
      case key
      when "first_name" then person.first_name.to_s
      when "last_name" then person.last_name.to_s
      when "name" then person.name.to_s
      when "chapter_name" then person.primary_chapter&.name.to_s
      else person.custom_field_values[key].to_s
      end
    end
  end
end
