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

  test "banner overlay defaults to light and rejects unknown values" do
    assert_equal "light", Setting.new.banner_overlay
    setting = Setting.new(banner_overlay: "rainbow")
    assert_not setting.valid?
    assert_includes setting.errors[:banner_overlay], "is not included in the list"
  end

  test "accepts an image banner" do
    setting = Setting.new
    setting.banner.attach(io: file_fixture("banner.png").open, filename: "banner.png", content_type: "image/png")
    assert setting.valid?
  end

  test "rejects a non-image banner" do
    setting = Setting.new
    setting.banner.attach(io: StringIO.new("not an image"), filename: "x.txt", content_type: "text/plain")
    assert_not setting.valid?
    assert_includes setting.errors[:banner], "must be a JPEG, PNG, GIF, or WebP image"
  end
end
