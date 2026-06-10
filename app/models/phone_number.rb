# Normalizes phone numbers to E.164 (US-biased: 10-digit numbers get +1).
module PhoneNumber
  def self.normalize(value)
    return nil if value.blank?

    digits = value.to_s.gsub(/\D/, "")
    digits = "1#{digits}" if digits.length == 10
    return value.to_s.strip if digits.length < 11 || digits.length > 15

    "+#{digits}"
  end

  def self.valid?(value)
    normalize(value).to_s.match?(/\A\+\d{11,15}\z/)
  end

  # Display format: "+18058784343" -> "(805) 878-4343". Non-US numbers and
  # unrecognized values are returned as-is.
  def self.format(value)
    return value if value.blank?

    if (match = value.to_s.match(/\A\+1(\d{3})(\d{3})(\d{4})\z/))
      "(#{match[1]}) #{match[2]}-#{match[3]}"
    else
      value
    end
  end
end
