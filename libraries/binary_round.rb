# frozen_string_literal: true
class BinaryRound
  attr_reader :mb

  def self.call(*args)
    new(*args).call
  end

  def initialize(mb)
    @mb = mb
  end

  def call
    # The output is a human readable string that ends with "GB", "MB" or "kB" if over 1023
    # The output may be up to 6.25% less than the original value because of the rounding.

    value = mb * 1024 * 1024
    multiplier = 1

    # Truncate value to 4 most significant bits
    while value >= 16
      value = (value / 2).floor
      multiplier *= 2
    end

    # Factor any remaining powers of 2 into the multiplier
    while value == 2 * (value / 2).floor
      value = (value / 2).floor
      multiplier *= 2
    end

    # Factor enough powers of 2 back into the value to
    # leave the multiplier as a power of 1024 that can
    # be represented as units of "GB", "MB" or "kB".
    if multiplier >= 1024 * 1024 * 1024
      while multiplier > 1024 * 1024 * 1024
        value = 2 * value
        multiplier = (multiplier / 2).floor
      end
      multiplier = 1
      units = "GB"

    elsif multiplier >= 1024 * 1024
      while multiplier > 1024 * 1024
        value = 2 * value
        multiplier = (multiplier / 2).floor
      end
      multiplier = 1
      units = "MB"

    elsif multiplier >= 1024
      while multiplier > 1024
        value = 2 * value
        multiplier = (multiplier / 2).floor
      end
      multiplier = 1
      units = "kB"

    else
      units = ""
    end

    # human readable string
    "#{multiplier * value}#{units}"
  end
end
