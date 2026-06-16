module Billing
  # Safety net for pre-auth holds. A delivered/failed message normally settles
  # via Twilio's status callback, but if that callback never arrives the hold
  # would linger and keep funds reserved forever. This periodically settles
  # (or releases) holds older than the cutoff.
  class ReconcileHoldsJob < ApplicationJob
    queue_as :default

    STALE_AFTER = 6.hours

    def perform
      cutoff = STALE_AFTER.ago
      Message.where.not(hold_microcents: nil)
             .where(cost_microcents: nil)
             .where("COALESCE(sent_at, created_at) < ?", cutoff)
             .find_each do |message|
        if message.organization.sms_billable?
          ChargeMessage.new(message).call # settles using the estimate (no Twilio price)
        else
          message.organization.release_sms_hold!(message)
        end
      end
    end
  end
end
