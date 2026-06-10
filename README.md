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
| Texting | Two-way inbox (live via Turbo Streams), templates, keywords with auto-replies, blasts (now/scheduled), STOP/START opt-out, delivery stats |
| Email | Rich-text blasts to segments, open tracking, unsubscribe links, scheduling |
| Events | Public RSVP pages, capacity/waitlists, 24h SMS reminders, check-in |
| Forms | Signup forms & petitions with goals, public pages, submissions upsert people |
| Automations | Workflows triggered by keywords, tags, form submissions, RSVPs; steps: SMS, email, tag, wait, notify |
| Reporting | Dashboard with per-chapter filtering: growth, reply rates, open rates, attendance |

Deferred for now: browser calling/phonebanks, payments (Stripe donations/dues).

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
- **Events**: `/o/riverside-united/events` → RSVP, then check people in from
  the admin event page.

## Twilio setup (real SMS)

1. Buy a phone number per chapter in the Twilio console and set it on the
   chapter (Settings → Chapters).
2. Set env vars: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and optionally
   `TWILIO_FROM_NUMBER` (fallback when a chapter has no number).
3. Point the number's webhooks at your app (use [ngrok](https://ngrok.com) in
   development: `ngrok http 3000`):
   - Messaging → "A message comes in": `POST https://<host>/webhooks/twilio/inbound_sms`
   - Status callback: `POST https://<host>/webhooks/twilio/sms_status`

Webhook signatures are validated automatically when Twilio credentials are set.

For email, configure SMTP via Action Mailer in production (e.g. Resend, SES)
and set `MAIL_FROM`.

## Development

```sh
bin/ci         # rubocop + brakeman + full test suite (same as CI)
bin/rails test # tests only
```
