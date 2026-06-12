class Event < ApplicationRecord
  include Scopable
  include LanguageVariants

  EVENT_TYPES = { "in_person" => "In-Person", "virtual" => "Virtual", "hybrid" => "Hybrid" }.freeze
  RECURRENCE_FREQUENCIES = %w[none daily weekly monthly].freeze

  belongs_to :host, class_name: "User", optional: true
  belongs_to :invited_segment, class_name: "Segment", optional: true
  belongs_to :submitted_by, class_name: "Person", optional: true
  has_many :event_sessions, -> { order(:starts_at) }, dependent: :destroy
  has_many :rsvps, dependent: :destroy
  has_many :attendees, through: :rsvps, source: :person
  has_many :sms_templates, dependent: :nullify
  has_many :event_co_hosts, dependent: :destroy
  has_many :co_host_organizations, through: :event_co_hosts, source: :organization

  validates :title, :starts_at, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES.keys }
  validates :recurrence_frequency, inclusion: { in: RECURRENCE_FREQUENCIES }

  scope :approved, -> { where(approved: true) }
  scope :listed, -> { approved.where(unlisted: false) }
  # An event is upcoming while any of its sessions is in the future.
  scope :upcoming, -> { where(id: EventSession.upcoming.select(:event_id)).order(:starts_at) }
  scope :past, -> { where.not(id: EventSession.upcoming.select(:event_id)).order(starts_at: :desc) }

  after_save :sync_primary_session
  after_commit :generate_recurring_sessions, if: -> { recurrence_frequency != "none" }

  def event_type_label = EVENT_TYPES[event_type]

  def display_time_zone = time_zone.presence || organization.time_zone

  def tags = tag_list.to_s.split(",").map(&:strip).compact_blank

  def primary_session
    event_sessions.find_by(is_primary: true) || event_sessions.first
  end

  def next_session
    event_sessions.upcoming.first
  end

  def yes_rsvps = rsvps.where(status: "yes")

  def full?(session = nil)
    session ? session.full? : (capacity.present? && yes_rsvps.count >= capacity)
  end

  # Creates or updates an RSVP for one session (defaults to the next upcoming
  # one). New "yes" RSVPs over capacity become waitlist; existing RSVPs can
  # change their answer (yes/no/maybe).
  def rsvp_for!(person, session: nil, status: "yes")
    session ||= next_session || primary_session
    raise ActiveRecord::RecordInvalid.new(Rsvp.new) if session.nil?

    if (rsvp = rsvps.find_by(person: person, event_session: session))
      rsvp.update!(status: status) unless rsvp.status == status || rsvp.status == "waitlist"
      return rsvp
    end

    applied = (status == "yes" && session.full?) ? "waitlist" : status
    rsvp = rsvps.create!(person: person, event_session: session, status: applied)
    Activity.record!(person: person, kind: "rsvp_created", subject: rsvp, data: { "event" => title, "status" => applied })
    Workflow.fire(trigger: "rsvp_created", person: person, param: id, payload: { status: applied })
    rsvp
  end

  def check_in!(rsvp)
    rsvp.update!(attended: !rsvp.attended?)
    if rsvp.attended?
      Activity.record!(person: rsvp.person, kind: "event_attended", subject: rsvp, data: { "event" => title })
      Workflow.fire(trigger: "event_attended", person: rsvp.person, param: id)
    end
    rsvp
  end

  def reminder_body_for(language)
    variant_for(language)&.dig("body").presence || reminder_body
  end

  # Public no-login link for hosts to manage RSVPs and attendance.
  def host_token!
    update!(host_token: SecureRandom.base58(20)) if host_token.blank?
    host_token
  end

  # Shared with another organization to co-host this event.
  def cohost_code!
    update!(cohost_code: SecureRandom.base58(12)) if cohost_code.blank?
    cohost_code
  end

  private

  # The event's own starts_at/ends_at columns mirror its primary session so
  # list ordering and legacy callers keep working.
  def sync_primary_session
    session = primary_session
    if session.nil?
      event_sessions.create!(starts_at: starts_at, ends_at: ends_at, is_primary: true)
    elsif session.starts_at != starts_at || session.ends_at != ends_at
      session.update!(starts_at: starts_at, ends_at: ends_at)
    end
  end

  def generate_recurring_sessions
    Event::GenerateSessionsJob.perform_later(self)
  end
end
