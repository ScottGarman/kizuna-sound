require "test_helper"

class SettingsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @audio = fixture_file_upload("sample.wav", "audio/wav")
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
    assert_equal [ "Bandcamp", "Newsletter" ], Setting.current.links.pluck(:title)

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

  test "admin can disable tags" do
    log_in
    patch settings_path, params: { setting: { tags_enabled: "0" } }
    assert_redirected_to settings_path
    assert_not Setting.current.tags_enabled?
  end

  test "disabling tags hides the browse-by-tag panel and ignores tag filtering" do
    log_in
    post sounds_path, params: { sound: { title: "Rainy", audio: @audio, new_tag_names: "rain" } }
    post sounds_path, params: { sound: { title: "Windy", audio: @audio, new_tag_names: "wind" } }
    Setting.create!(tags_enabled: false)
    reset!

    get root_path
    assert_response :success
    assert_select "*", text: /Browse by tag/, count: 0

    # A stray ?tag= URL no longer filters: every sound still shows.
    get root_path(tag: "rain")
    assert_response :success
    assert_select "a", text: "Rainy"
    assert_select "a", text: "Windy"
    assert_select "a", text: "Clear filter", count: 0
  end

  test "disabling tags hides tags on the sound show page" do
    log_in
    post sounds_path, params: { sound: { title: "Tagged", audio: @audio, new_tag_names: "rain" } }
    sound = Sound.order(:created_at).last
    Setting.create!(tags_enabled: false)
    reset!

    get sound_path(sound)
    assert_response :success
    assert_select "*", text: /Tags:/, count: 0
  end

  test "admin can upload a banner and it appears behind the feed header" do
    log_in
    banner = fixture_file_upload("banner.png", "image/png")
    patch settings_path, params: { setting: { banner: banner } }
    assert_redirected_to settings_path
    assert Setting.current.banner.attached?

    get root_path
    assert_response :success
    # The header uses the uploaded banner as a background image.
    assert_select "header[style*='background-image']"
    assert_select "header[style*='/rails/active_storage/']"
  end

  test "uploading a non-image banner is rejected" do
    log_in
    bad = fixture_file_upload("not_audio.txt", "text/plain")
    patch settings_path, params: { setting: { banner: bad } }
    assert_response :unprocessable_entity
    assert_not Setting.current.banner.attached?
  end

  test "dark overlay darkens the banner and uses light text" do
    log_in
    banner = fixture_file_upload("banner.png", "image/png")
    patch settings_path, params: { setting: { banner: banner, banner_overlay: "dark" } }
    assert_equal "dark", Setting.current.banner_overlay
    reset!

    get root_path
    assert_response :success
    assert_select "header div.bg-black\\/50"
    assert_select "header h1.text-white"
  end

  test "none overlay renders no scrim" do
    log_in
    banner = fixture_file_upload("banner.png", "image/png")
    patch settings_path, params: { setting: { banner: banner, banner_overlay: "none" } }
    reset!

    get root_path
    assert_response :success
    assert_select "header div.bg-white\\/70", count: 0
    assert_select "header div.bg-black\\/50", count: 0
  end

  test "flash messages render below the banner on the feed" do
    log_in
    banner = fixture_file_upload("banner.png", "image/png")
    patch settings_path, params: { setting: { banner: banner } }

    # Uploading a sound redirects to the feed with a flash notice.
    post sounds_path, params: { sound: { title: "Hi", audio: @audio } }
    follow_redirect!
    assert_response :success

    banner_pos = response.body.index("background-image")
    flash_pos = response.body.index("was uploaded")
    assert banner_pos, "expected the banner to render"
    assert flash_pos, "expected the flash notice to render"
    assert banner_pos < flash_pos, "expected the banner to appear above the flash message"
  end

  test "admin can remove the banner" do
    log_in
    setting = Setting.create!
    setting.banner.attach(io: file_fixture("banner.png").open, filename: "banner.png", content_type: "image/png")

    patch settings_path, params: { setting: { remove_banner: "1" } }
    assert_redirected_to settings_path
    assert_not Setting.current.banner.attached?
  end
end
