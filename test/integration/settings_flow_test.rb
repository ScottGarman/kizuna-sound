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

  test "update requires login" do
    patch settings_path, params: { setting: { title: "Sneaky" } }
    assert_redirected_to login_path
  end

  test "admin can set the site title and it appears on the feed" do
    log_in
    patch settings_path, params: { setting: { title: "My Sound Collection" } }
    assert_redirected_to settings_path
    assert_equal "My Sound Collection", Setting.current.title

    get root_path
    assert_response :success
    assert_select "h1", text: "My Sound Collection"
    assert_select "title", text: "My Sound Collection"
  end

  test "feed falls back to the default heading when no title is set" do
    Setting.delete_all
    get root_path
    assert_response :success
    assert_select "h1", text: "Sounds"
    assert_select "title", text: "Kizuna Sound"
  end

  test "admin can set the about text and it appears on the feed" do
    log_in
    patch settings_path, params: { setting: { about: "Field recordings from my travels." } }
    assert_redirected_to settings_path
    assert_equal "Field recordings from my travels.", Setting.current.about

    get root_path
    assert_response :success
    assert_select "p", text: "Field recordings from my travels."
  end

  test "about text is not rendered when blank" do
    Setting.delete_all
    Setting.create!(about: "")
    get root_path
    assert_response :success
    assert_select "header p", count: 0
  end

  test "about text is HTML-escaped, not injected as markup" do
    log_in
    patch settings_path, params: { setting: { about: "<script>alert('x')</script>" } }

    get root_path
    assert_response :success
    assert_not_includes response.body, "<script>alert('x')</script>"
  end

  test "admin can add links and they appear on the feed opening in a new tab" do
    log_in
    patch settings_path, params: {
      setting: {
        links_attributes: {
          "0" => { title: "Bandcamp", url: "https://example.bandcamp.com" },
          "1" => { title: "Newsletter", url: "https://example.com/news" }
        }
      }
    }
    assert_redirected_to settings_path
    assert_equal ["Bandcamp", "Newsletter"], Setting.current.links.pluck(:title)

    get root_path
    assert_response :success
    assert_select "header a[href='https://example.bandcamp.com'][target='_blank'][rel='noopener']",
                  text: "Bandcamp"
  end

  test "blank link rows are dropped" do
    log_in
    assert_no_difference "Link.count" do
      patch settings_path, params: {
        setting: { links_attributes: { "0" => { title: "", url: "" } } }
      }
    end
    assert_redirected_to settings_path
  end

  test "a link with a dangerous url scheme is rejected" do
    log_in
    assert_no_difference "Link.count" do
      patch settings_path, params: {
        setting: { links_attributes: { "0" => { title: "Bad", url: "javascript:alert(1)" } } }
      }
    end
    assert_response :unprocessable_entity
  end

  test "admin can remove an existing link" do
    log_in
    setting = Setting.create!
    link = setting.links.create!(title: "Old", url: "https://old.example")

    assert_difference "Link.count", -1 do
      patch settings_path, params: {
        setting: { links_attributes: { "0" => { id: link.id, _destroy: "1" } } }
      }
    end
    assert_redirected_to settings_path
  end
end
