# Mobilize

A Solidarity Tech–style organizing platform: CRM, two-way SMS, email blasts,
events, petitions/forms, and automations — built with Rails 8, Hotwire, and
SQLite (Solid Queue/Cable/Cache, no Redis or Postgres required).

## Concepts

Mirrors [Solidarity Tech's core concepts](https://www.solidarity.tech/docs/solidarity-tech-concepts-terms):

- **Organization → Chapters** — each chapter has its own local phone number.
  Outbound texts go out from the recipient's primary chapter's number; inbound
  texts route to the chapter that owns the receiving number.
- **People** — phone-first contact records (phone OR email required). A
  person's primary chapter is auto-assigned from their zip code (with the
  org's default chapter as fallback).
- **Team members** — users linked to a person record, with admin/organizer
  roles scoped org-wide or to a single chapter.
- **Scoped resources** — segments, blasts, events, forms, and workflows belong
  to either the whole organization or one chapter; chapter-scoped team members
  only see what's in their scope.

## Features

| Pillar | What's included |
|---|---|
| CRM | People CRUD, CSV import, tags, notes, custom fields, activity feed, segment builder |
| Texting | Two-way inbox (live via Turbo Streams), MMS attachments, templates (global + per-event, with a picker in the inbox and workflows), keywords with auto-replies, STOP/START opt-out |
| Text blasts | Now/scheduled sends, live character/segment counter with cost estimate, test sends, clone, per-language message variants, link shortening with per-recipient click tracking and form-submission attribution, texting-hours compliance (queue/skip/override, recipient-timezone aware), delivery + click stats |
| Email | Rich-text blasts to segments, email templates, open tracking, unsubscribe links, scheduling |
| Events | Multi-session events with daily/weekly/monthly recurrence (rolling auto-generation), public RSVP pages with Yes/Maybe/No, per-session capacity/waitlists, RSVP confirmations N days out, day-before SMS + email reminders with attached calendar invite (customizable, per-language), iCal subscription feed, no-login Host Tools link, supporter-submitted events with approval queue, cross-org co-hosting via invite code, clone, unlisted events, tags, invited lists with one-click blast, attendance webhook for virtual platforms |
| Forms | Signup forms & petitions with goals, public pages, submissions upsert people |
| Donations | Manual entry plus a tokenized webhook for payment processors; feeds the donation automation trigger |
| Automations | Multiple triggers per workflow (keyword, tag, form, RSVP w/ status filter, attendance, donation, link click, email open, person created, incoming text with contains/exact/regex filter); actions: SMS, email, tag/untag, wait, notify member (email or SMS), update property, webhook, RSVP to event; decision router with list-based branches (first-match or all-matches, "everyone else" branch, nested steps); once-per-person enrollment with manual re-enroll; goals that exit runs early; per-step reach counts and goal rate |
| Reporting | Dashboard with per-chapter filtering: growth, reply rates, open rates, attendance |

Deferred for now: browser calling/phonebanks, donation processing (donations are records only — usage billing for SMS is handled via Stripe, see below), AI translation of message variants, direct Zoom API integration (use the attendance webhook instead).

## Getting started

```sh
bin/setup            # installs gems, prepares DB
bin/rails db:seed    # demo org with chapters, people, petition, workflow
bin/dev              # web server + Solid Queue worker + Tailwind watcher
```

Sign in at http://localhost:3000 with **demo@mobilize.test / password**, or
create your own organization at `/registration/new`.

Without Twilio credentials the app uses a **fake SMS provider**: sends are
logged and recorded, so everything (inbox, blasts, keywords, workflows) is
demoable locally. Emails open in the browser via letter_opener.

### Demo flows to try

- **Scheduled blast**: Blasts → Meeting announcement → schedule it a minute out;
  Solid Queue fires it and per-recipient statuses appear on the blast page.
- **Inbound text**: simulate Twilio with curl —

  ```sh
  curl -X POST localhost:3000/webhooks/twilio/inbound_sms \
    -d "To=%2B15550100002" -d "From=%2B15550110001" -d "Body=JOIN" -d "MessageSid=SM1"
  ```

  Maria appears in the North Side inbox, gets tagged "interested", and receives
  the keyword auto-reply.
- **Petition + workflow**: visit `/o/riverside-united/f/save-our-library`,
  sign it, and watch the "Welcome new signers" workflow tag + text the signer.
- **Events**: `/o/riverside-united/events` → RSVP (Yes/Maybe/No), then check
  people in from the admin event page or the no-login Host Tools link. Add
  extra sessions or a weekly recurrence and watch future sessions appear.
- **Donation webhook**: the Donations page shows your org's webhook URL — POST
  `{ "phone": "...", "amount_cents": 2500, "source": "actblue" }` to it and the
  donation appears, firing any donation-triggered automations.
- **Link tracking**: send a blast whose body contains a URL — each recipient
  gets a unique short link, and clicks show up on the blast page.

## Twilio setup (real SMS)

1. Set env vars: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and optionally
   `TWILIO_FROM_NUMBER` (fallback when a chapter has no number).
2. Provision a number per chapter from **Settings → Chapters → Edit**: enter an
   area code and the app finds, buys, and wires up an SMS-capable local number
   automatically.
3. Twilio webhooks are configured automatically on provisioned numbers (when
   `APP_HOST` is set). For numbers added manually, point their webhooks at:
   - Messaging → "A message comes in": `POST https://<host>/webhooks/twilio/inbound_sms`
   - Status callback: `POST https://<host>/webhooks/twilio/sms_status`

Webhook signatures are validated automatically when Twilio credentials are set.
Inbound MMS arrives through the same webhook — media is downloaded and attached
to the conversation.

In production also set **`APP_HOST`** (e.g. `app.example.org`) — it's used to
build short links, MMS media URLs, and Twilio status callbacks. Development
falls back to `localhost:3000`.

For email, configure SMTP via Action Mailer in production (e.g. Resend, SES)
and set `MAIL_FROM`.

## Billing (Stripe)

Organizations pay for their own SMS usage via a prepaid balance. Because each
text costs a fraction of a cent — far less than Stripe's per-charge fee — the
card isn't charged per message. Instead an org **tops up** a dollar balance
(Settings → Billing), and each message is debited at Twilio's actual cost
(captured from the status callback). When a card is on file, sending is gated
on a positive balance; orgs that haven't set up billing are unaffected.

1. Set env vars: `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, and
   `STRIPE_WEBHOOK_SECRET`.
2. Point Stripe's webhook at `POST https://<host>/webhooks/stripe` and subscribe
   to `checkout.session.completed` (used to save the card after Checkout).
3. Optional tuning: `TWILIO_SMS_PRICE_MICROCENTS` (fallback per-segment price
   when Twilio hasn't reported one, default `790` ≈ $0.0079) and
   `TWILIO_NUMBER_PRICE_MICROCENTS` (charged on provisioning, default `115000`
   ≈ $1.15). Per-message markup is pass-through by default (`sms_markup_bps`
   on the organization, in basis points).

Without `STRIPE_SECRET_KEY` the app uses an in-memory fake (card always on
file, top-ups succeed instantly) so the flow is fully demoable offline.

## Development

```sh
bin/ci         # rubocop + brakeman + full test suite (same as CI)
bin/rails test # tests only
```
