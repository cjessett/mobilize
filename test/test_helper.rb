ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    # Each test gets a fresh fake SMS/billing provider so deliveries and
    # charges can be asserted in isolation.
    setup do
      Sms.provider = Sms::FakeProvider.new
      Billing.provider = Billing::FakeProvider.new
    end

    def fake_sms = Sms.provider
    def fake_billing = Billing.provider
  end
end
