require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "current creates the singleton row when none exists" do
    Setting.delete_all
    assert_difference "Setting.count", 1 do
      Setting.current
    end
  end

  test "current reuses the existing row" do
    first = Setting.current
    assert_no_difference "Setting.count" do
      assert_equal first, Setting.current
    end
  end
end
