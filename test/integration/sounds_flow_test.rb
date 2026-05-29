require "test_helper"

class SoundsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @audio = fixture_file_upload("sample.wav", "audio/wav")
  end

  def log_in
    post login_path, params: { email: @admin.email, password: "password" }
  end

  test "feed is public and reachable when logged out" do
    get root_path
    assert_response :success
  end

  test "upload form requires login" do
    get new_sound_path
    assert_redirected_to login_path
  end

  test "create requires login" do
    assert_no_difference "Sound.count" do
      post sounds_path, params: { sound: { title: "Sneaky", audio: @audio } }
    end
    assert_redirected_to login_path
  end

  test "admin can log in, upload, see it in the feed, and download it" do
    log_in
    assert_redirected_to root_path

    assert_difference "Sound.count", 1 do
      post sounds_path, params: { sound: { title: "Morning Birds", audio: @audio } }
    end
    sound = Sound.order(:created_at).last
    assert sound.audio.attached?
    assert_redirected_to root_path

    get root_path
    assert_response :success
    assert_select "a", text: "Morning Birds"

    # The title links to a download (attachment disposition) of the blob.
    get rails_blob_path(sound.audio, disposition: "attachment")
    assert_response :redirect # Active Storage redirects to the stored file
  end

  test "upload rejects a non-audio file" do
    log_in
    # Active Storage sniffs the actual bytes (via Marcel), so a real non-audio
    # file is detected as text/plain regardless of any declared content type.
    bad = fixture_file_upload("not_audio.txt", "text/plain")
    assert_no_difference "Sound.count" do
      post sounds_path, params: { sound: { title: "Not audio", audio: bad } }
    end
    assert_response :unprocessable_entity
  end

  test "admin can delete a sound" do
    log_in
    post sounds_path, params: { sound: { title: "To delete", audio: @audio } }
    sound = Sound.order(:created_at).last

    assert_difference "Sound.count", -1 do
      delete sound_path(sound)
    end
    assert_redirected_to root_path
  end
end
