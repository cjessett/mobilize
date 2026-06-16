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

    # Each test gets a fresh fake SMS/billing/flag provider so deliveries,
    # charges, and feature gates can be asserted in isolation. The flag
    # provider defaults flags on in test (see FeatureFlags::FakeProvider).
    setup do
      Sms.provider = Sms::FakeProvider.new
      Billing.provider = Billing::FakeProvider.new
      FeatureFlags.provider = FeatureFlags::FakeProvider.new
    end

    def fake_sms = Sms.provider
    def fake_billing = Billing.provider

    def disable_billing_feature(organization = nil)
      FeatureFlags.provider.set(FeatureFlags::CHAPTER_BILLING, false, organization: organization)
    end
  end
end
