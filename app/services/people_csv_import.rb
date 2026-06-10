require "csv"

# Imports people from a CSV with headers:
#   first_name,last_name,phone,email,zip_code,city,state,address,tags
# Rows are matched to existing people by phone (then email) and updated.
class PeopleCsvImport
  Result = Struct.new(:created, :updated, :errors, keyword_init: true)

  def initialize(organization, io)
    @organization = organization
    @io = io
  end

  def call
    created = 0
    updated = 0
    errors = []

    CSV.parse(@io.read, headers: true, header_converters: ->(h) { h.to_s.strip.downcase }).each_with_index do |row, index|
      phone = PhoneNumber.normalize(row["phone"])
      email = row["email"].to_s.strip.downcase.presence
      person = find_existing(phone, email) || @organization.people.new
      was_new = person.new_record?

      person.assign_attributes(
        first_name: row["first_name"].presence || person.first_name,
        last_name: row["last_name"].presence || person.last_name,
        phone: phone || person.phone,
        email: email || person.email,
        zip_code: row["zip_code"].presence || person.zip_code,
        city: row["city"].presence || person.city,
        state: row["state"].presence || person.state,
        address: row["address"].presence || person.address
      )
      person.tag_list = row["tags"] if row["tags"].present?

      if person.save
        was_new ? created += 1 : updated += 1
      else
        errors << "Row #{index + 2}: #{person.errors.full_messages.to_sentence}"
      end
    end

    Result.new(created:, updated:, errors:)
  rescue CSV::MalformedCSVError => e
    Result.new(created: 0, updated: 0, errors: [ "Invalid CSV: #{e.message}" ])
  end

  private

  def find_existing(phone, email)
    (phone && @organization.people.find_by(phone: phone)) ||
      (email && @organization.people.find_by(email: email))
  end
end
