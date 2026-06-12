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
| Events | Public RSVP pages, capacity/waitlists, 24h SMS reminders, check-in |
| Forms | Signup forms & petitions with goals, public pages, submissions upsert people |
| Donations | Manual entry plus a tokenized webhook for payment processors; feeds the donation automation trigger |
| Automations | Multiple triggers per workflow (keyword, tag, form, RSVP w/ status filter, attendance, donation, link click, email open, person created, incoming text with contains/exact/regex filter, Instagram comment/DM/follow); actions: SMS, email, tag/untag, wait, notify member (email or SMS), update property, webhook, RSVP to event, Instagram DM (with optional quick-reply or URL buttons); decision router with list-based branches (first-match or all-matches, "everyone else" branch, nested steps); once-per-person enrollment with manual re-enroll; goals that exit runs early; per-step reach counts and goal rate |
| Reporting | Dashboard with per-chapter filtering: growth, reply rates, open rates, attendance |

Deferred for now: browser calling/phonebanks, real payment processing (donations are records only), AI translation of message variants.

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
- **Donation webhook**: the Donations page shows your org's webhook URL — POST
  `{ "phone": "...", "amount_cents": 2500, "source": "actblue" }` to it and the
  donation appears, firing any donation-triggered automations.
- **Link tracking**: send a blast whose body contains a URL — each recipient
  gets a unique short link, and clicks show up on the blast page.

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
Inbound MMS arrives through the same webhook — media is downloaded and attached
to the conversation.

In production also set **`APP_HOST`** (e.g. `app.example.org`) — it's used to
build short links, MMS media URLs, and Twilio status callbacks. Development
falls back to `localhost:3000`.

For email, configure SMTP via Action Mailer in production (e.g. Resend, SES)
and set `MAIL_FROM`.

## Instagram setup (DM-from-comment campaigns)

Instagram automations let you DM users who comment on your posts (with optional keyword triggers), respond to button taps in DMs with follow-up messages, and send welcome DMs to new followers. Each campaign is a separate workflow.

### 1 — Create a Meta App

1. Go to [developers.facebook.com](https://developers.facebook.com) → **My Apps → Create App → Business**
2. Add the **Instagram** product → **Set Up**
3. Under **Instagram → Settings**, connect the Facebook Page that is linked to your Instagram Business/Creator account

### 2 — Configure OAuth

In your Meta app dashboard:

1. **App Settings → Basic**: copy your **App ID** and **App Secret**
2. **Facebook Login → Settings → Valid OAuth Redirect URIs**: add `https://<your-host>/settings/instagram/callback`
3. **App Review → Permissions**: request `instagram_manage_messages`, `instagram_manage_comments`, `pages_messaging`, `pages_show_list`, `pages_read_engagement` (in development you can use these as a test user without review)

Set env vars:
```
INSTAGRAM_APP_ID=<your app id>
INSTAGRAM_APP_SECRET=<your app secret>
INSTAGRAM_WEBHOOK_VERIFY_TOKEN=<any random string you choose>
```

### 3 — Connect in Mobilize

Go to **Settings → Organization** and click **Connect Instagram**. You'll be redirected to Meta to authorize the app. If multiple Instagram accounts are found you'll be prompted to choose one. The account name is shown once connected.

### 4 — Register the webhook

In your Meta app dashboard → **Webhooks → Instagram**:

- Callback URL: `https://<your-host>/webhooks/instagram`
- Verify token: the same value as `INSTAGRAM_WEBHOOK_VERIFY_TOKEN`
- Subscribe to fields: **comments**, **messages**, **follows**

Webhook signatures are validated automatically using `INSTAGRAM_APP_SECRET`.

### 5 — Build campaigns

Each campaign is a **Workflow**. Example two-step flow:

| Workflow | Trigger | Keyword | Action |
|----------|---------|---------|--------|
| "Event RSVP prompt" | Instagram comment | `rsvp` | Send Instagram DM: "Thanks for your interest! 👇" + quick-reply button "Send me the link!" (payload: `SEND_LINK`) |
| "Send RSVP link" | Instagram DM / button tap | `SEND_LINK` | Send Instagram DM: "Here it is!" + URL button "RSVP →" pointing to your event |
| "Welcome followers" | Instagram follow | *(any)* | Send Instagram DM: "Welcome! Here's what we're about…" |

Leave the keyword blank to match any comment/DM.

## Development

```sh
bin/ci         # rubocop + brakeman + full test suite (same as CI)
bin/rails test # tests only
```
