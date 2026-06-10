# Demo data: an organization with two chapters, people, segments, blasts,
# a keyword, a workflow, an event, and a petition. Idempotent.
#
# Sign in with demo@mobilize.test / password after seeding.

org = Organization.find_or_create_by!(slug: "riverside-united") do |o|
  o.name = "Riverside United"
  o.time_zone = "America/Chicago"
end

org.chapters.find_or_create_by!(name: "Downtown") do |c|
  c.default = true
  c.phone_number = "+15550100001"
end
north = org.chapters.find_or_create_by!(name: "North Side") do |c|
  c.phone_number = "+15550100002"
end
north.zip_codes_list = "60640, 60660, 60626" if north.chapter_zip_codes.none?
north.save!

admin_person = org.people.find_or_create_by!(email: "demo@mobilize.test") do |p|
  p.first_name = "Demo"
  p.last_name = "Admin"
  p.phone = "+15550110000"
end

admin = User.find_or_create_by!(email_address: "demo@mobilize.test") do |u|
  u.password = "password"
  u.person = admin_person
end
org.memberships.find_or_create_by!(user: admin) do |m|
  m.role = "admin"
  m.access_scope = org
end

[
  [ "Maria", "Lopez", "+15550110001", "60640", %w[member volunteer] ],
  [ "James", "Chen", "+15550110002", "60660", %w[member] ],
  [ "Aisha", "Johnson", "+15550110003", "60601", %w[volunteer] ],
  [ "Sam", "Rivera", "+15550110004", "60626", [] ],
  [ "Dana", "Kim", "+15550110005", "60601", %w[member] ],
  [ "Luis", "Garcia", "+15550110006", "60640", %w[member steward] ]
].each do |first, last, phone, zip, tags|
  person = org.people.find_or_create_by!(phone: phone) do |p|
    p.first_name = first
    p.last_name = last
    p.zip_code = zip
    p.email = "#{first.downcase}@example.com"
  end
  person.update!(tag_list: tags.join(", ")) if tags.any? && person.tags.none?
end

members_tag = org.tags.find_or_create_by!(name: "member")
org.segments.find_or_create_by!(name: "Members") do |s|
  s.access_scope = org
  s.definition = { "match" => "all", "conditions" => [ { "type" => "tag", "op" => "has", "tag_id" => members_tag.id } ] }
end
org.segments.find_or_create_by!(name: "North Side people") do |s|
  s.access_scope = north
  s.definition = { "match" => "all", "conditions" => [ { "type" => "chapter", "chapter_id" => north.id } ] }
end

org.sms_templates.find_or_create_by!(name: "Meeting reminder") do |t|
  t.body = "Hi {{first_name}}, don't forget our chapter meeting this week! Reply YES if you can make it."
end

join_tag = org.tags.find_or_create_by!(name: "interested")
org.keywords.find_or_create_by!(word: "join") do |k|
  k.tag = join_tag
  k.reply_body = "Thanks {{first_name}}! An organizer will text you shortly."
end

workflow = org.workflows.find_or_create_by!(name: "Welcome new signers") do |w|
  w.trigger = "form_submitted"
  w.trigger_param = "save-our-library"
  w.access_scope = org
end
if workflow.workflow_steps.none?
  workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "petition-signer" })
  workflow.workflow_steps.create!(position: 1, action: "send_sms", params: { "body" => "Thanks for signing, {{first_name}}! We'll keep you posted." })
end

org.events.find_or_create_by!(title: "Monthly Member Meeting") do |e|
  e.starts_at = 2.weeks.from_now.change(hour: 18, min: 30)
  e.location = "Riverside Community Center"
  e.capacity = 50
  e.access_scope = org
  e.description = "Our monthly all-member meeting. Pizza provided!"
end

form = org.forms.find_or_create_by!(slug: "save-our-library") do |f|
  f.title = "Save Our Library"
  f.kind = "petition"
  f.goal = 500
  f.description = "The city wants to cut library hours. Sign to tell the council: keep our library open!"
  f.access_scope = org
  f.apply_tag = org.tags.find_or_create_by!(name: "petition-signer")
end
if form.form_fields.none?
  form.form_fields.create!(position: 0, key: "first_name", label: "First name", required: true)
  form.form_fields.create!(position: 1, key: "last_name", label: "Last name")
  form.form_fields.create!(position: 2, key: "phone", label: "Phone")
  form.form_fields.create!(position: 3, key: "email", label: "Email")
  form.form_fields.create!(position: 4, key: "zip_code", label: "Zip code")
end

org.blasts.find_or_create_by!(name: "Meeting announcement") do |b|
  b.body = "Hi {{first_name}}! Our member meeting is in two weeks at the Riverside Community Center. RSVP: reply YES."
  b.segment = org.segments.find_by(name: "Members")
  b.access_scope = org
end

puts "Seeded #{org.name}: #{org.people.count} people, #{org.chapters.count} chapters."
puts "Sign in with demo@mobilize.test / password"
