require "test_helper"

class FeatureFlagsTest < ActiveSupport::TestCase
  setup { @org = organizations(:riverside) }

  test "fake provider defaults on in test" do
    assert FeatureFlags.enabled?(FeatureFlags::CHAPTER_BILLING, @org)
  end

  test "can be disabled per organization" do
    FeatureFlags.provider.set(FeatureFlags::CHAPTER_BILLING, false, organization: @org)

    assert_not FeatureFlags.enabled?(FeatureFlags::CHAPTER_BILLING, @org)
    assert FeatureFlags.enabled?(FeatureFlags::CHAPTER_BILLING, organizations(:other_org))
  end

  test "can be disabled globally" do
    FeatureFlags.provider.set(FeatureFlags::CHAPTER_BILLING, false)

    assert_not FeatureFlags.enabled?(FeatureFlags::CHAPTER_BILLING, @org)
  end
end
