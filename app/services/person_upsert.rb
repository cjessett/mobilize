# Finds or creates a person from public submissions (RSVPs, forms).
# Matches by phone first, then email; fills in any blank fields.
class PersonUpsert
  def initialize(organization, attributes)
    @organization = organization
    @attributes = attributes.symbolize_keys
  end

  def call
    phone = PhoneNumber.normalize(@attributes[:phone])
    email = @attributes[:email].to_s.strip.downcase.presence

    person = (phone && @organization.people.find_by(phone: phone)) ||
      (email && @organization.people.find_by(email: email)) ||
      @organization.people.new

    person.first_name = @attributes[:first_name] if person.first_name.blank? && @attributes[:first_name].present?
    person.last_name = @attributes[:last_name] if person.last_name.blank? && @attributes[:last_name].present?
    person.phone ||= phone
    person.email ||= email
    person.zip_code = @attributes[:zip_code] if person.zip_code.blank? && @attributes[:zip_code].present?

    custom = @attributes[:custom_field_values]
    person.custom_field_values = person.custom_field_values.merge(custom.stringify_keys) if custom.present?

    person.save!
    person
  end
end
