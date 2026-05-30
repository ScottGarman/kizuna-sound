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

  test "edit form requires login" do
    log_in
    post sounds_path, params: { sound: { title: "Editable", audio: @audio } }
    sound = Sound.order(:created_at).last
    reset!

    get edit_sound_path(sound)
    assert_redirected_to login_path
  end

  test "update requires login" do
    log_in
    post sounds_path, params: { sound: { title: "Editable", audio: @audio } }
    sound = Sound.order(:created_at).last
    reset!

    patch sound_path(sound), params: { sound: { title: "Hacked" } }
    assert_redirected_to login_path
    assert_equal "Editable", sound.reload.title
  end

  test "admin can edit a sound's title without replacing the audio" do
    log_in
    post sounds_path, params: { sound: { title: "Old Title", audio: @audio } }
    sound = Sound.order(:created_at).last
    original_blob_id = sound.audio.blob.id

    patch sound_path(sound), params: { sound: { title: "New Title" } }
    assert_redirected_to root_path

    sound.reload
    assert_equal "New Title", sound.title
    assert sound.audio.attached?
    assert_equal original_blob_id, sound.audio.blob.id
  end

  test "admin can replace the audio file when editing" do
    log_in
    post sounds_path, params: { sound: { title: "Replace Me", audio: @audio } }
    sound = Sound.order(:created_at).last
    original_blob_id = sound.audio.blob.id

    replacement = fixture_file_upload("sample.wav", "audio/wav")
    patch sound_path(sound), params: { sound: { title: "Replace Me", audio: replacement } }
    assert_redirected_to root_path

    sound.reload
    assert sound.audio.attached?
    assert_not_equal original_blob_id, sound.audio.blob.id
  end

  test "update rejects a blank title" do
    log_in
    post sounds_path, params: { sound: { title: "Keep me valid", audio: @audio } }
    sound = Sound.order(:created_at).last

    patch sound_path(sound), params: { sound: { title: "" } }
    assert_response :unprocessable_entity
    assert_equal "Keep me valid", sound.reload.title
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
