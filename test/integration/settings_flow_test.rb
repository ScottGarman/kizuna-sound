require "test_helper"

class SettingsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
  end

  def log_in
    post login_path, params: { email: @admin.email, password: "password" }
  end

  test "settings page requires login" do
    get settings_path
    assert_redirected_to login_path
  end

  test "admin can view the settings page" do
    log_in
    get settings_path
    assert_response :success
    assert_select "h1", text: "Settings"
  end
end
