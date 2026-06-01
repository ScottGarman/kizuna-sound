require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "current returns an unpersisted record when none exists" do
    Setting.delete_all
    assert_not Setting.current.persisted?
  end

  test "current returns the existing row when one exists" do
    existing = Setting.create!
    assert_equal existing, Setting.current
  end

  test "site_title falls back to a default when blank" do
    assert_equal "Sounds", Setting.new(title: "").site_title
    assert_equal "Sounds", Setting.new(title: nil).site_title
  end

  test "site_title uses the configured title when present" do
    assert_equal "My Sound Collection", Setting.new(title: "My Sound Collection").site_title
  end

  test "tags are enabled by default" do
    assert Setting.new.tags_enabled?
    assert Setting.current.tags_enabled?
  end
end
