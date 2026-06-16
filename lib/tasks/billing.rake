namespace :billing do
  # Grant Twilio credits to an org without charging a card (operator-only;
  # requires server access). Works across all orgs by slug.
  #
  #   bin/rails "billing:grant[riverside, 50, Paid cash 2026-06-16]"
  desc "Grant credits to an organization by slug: billing:grant[slug,dollars,note]"
  task :grant, [ :slug, :dollars, :note ] => :environment do |_task, args|
    org = Organization.find_by!(slug: args[:slug])
    dollars = BigDecimal(args[:dollars].to_s)
    raise ArgumentError, "dollars must be positive" unless dollars.positive?

    org.grant_credits!(
      amount_microcents: Money.from_dollars(dollars),
      description: args[:note].presence || "Credit grant (CLI)"
    )
    puts "Granted #{Money.format(Money.from_dollars(dollars))} to #{org.name}. New balance: #{org.reload.balance_display}."
  end
end
