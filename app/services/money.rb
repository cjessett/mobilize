require "bigdecimal"

# Internal monetary unit is the "microcent" = 1/1000 of a US cent
# ($0.00001). SMS costs are fractions of a cent, so storing whole cents
# would lose precision; microcents let us pass Twilio's price through exactly.
module Money
  MICROCENTS_PER_CENT = 1_000
  MICROCENTS_PER_DOLLAR = 100 * MICROCENTS_PER_CENT # 100_000

  module_function

  def from_dollars(dollars)
    (BigDecimal(dollars.to_s) * MICROCENTS_PER_DOLLAR).round
  end

  # Twilio reports price as a signed dollar string, e.g. "-0.00750".
  def from_twilio_price(price)
    (BigDecimal(price.to_s).abs * MICROCENTS_PER_DOLLAR).round
  end

  # Microcents -> whole cents (Stripe charges in cents), rounded to nearest.
  def to_cents(microcents)
    (microcents.to_i / MICROCENTS_PER_CENT.to_f).round
  end

  def to_dollars(microcents)
    microcents.to_i / MICROCENTS_PER_DOLLAR.to_f
  end

  # Human display. Shows extra precision for sub-cent amounts.
  def format(microcents)
    dollars = to_dollars(microcents)
    if microcents != 0 && dollars.abs < 0.01
      format_string = "$%.5f"
    else
      format_string = "$%.2f"
    end
    Kernel.format(format_string, dollars)
  end
end
