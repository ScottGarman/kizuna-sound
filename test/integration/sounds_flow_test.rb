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

  test "sound show page is public and renders the waveform player" do
    log_in
    post sounds_path, params: { sound: { title: "Playable", audio: @audio } }
    sound = Sound.order(:created_at).last
    reset!

    get sound_path(sound)
    assert_response :success
    assert_select "h1", text: "Playable"
    # The player partial wires up the waveform Stimulus controller with the blob URL.
    assert_select "[data-controller='waveform'][data-waveform-url-value=?]",
                  rails_blob_path(sound.audio)
  end

  test "feed links each sound title to its show page" do
    log_in
    post sounds_path, params: { sound: { title: "Linkable", audio: @audio } }
    sound = Sound.order(:created_at).last
    reset!

    get root_path
    assert_response :success
    assert_select "a[href=?]", sound_path(sound), text: "Linkable"
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

  test "uploading with new tag names creates and attaches normalized tags" do
    log_in
    post sounds_path, params: {
      sound: { title: "Tagged", audio: @audio, new_tag_names: "Ambient, Field Recording" }
    }
    sound = Sound.order(:created_at).last
    assert_equal [ "ambient", "field recording" ], sound.tags.order(:name).pluck(:name)
  end

  test "uploading reuses an existing tag instead of duplicating it" do
    existing = Tag.create!(name: "ambient")
    log_in
    assert_no_difference -> { Tag.where(name: "ambient").count } do
      post sounds_path, params: {
        sound: { title: "Reuse", audio: @audio, tag_ids: [ existing.id ], new_tag_names: "ambient" }
      }
    end
    sound = Sound.order(:created_at).last
    assert_equal [ existing.id ], sound.tag_ids
  end

  test "editing can add an existing tag via checkboxes" do
    log_in
    post sounds_path, params: { sound: { title: "Editable", audio: @audio } }
    sound = Sound.order(:created_at).last
    tag = Tag.create!(name: "rain")

    patch sound_path(sound), params: { sound: { title: "Editable", tag_ids: [ tag.id ] } }
    assert_redirected_to root_path
    assert_equal [ "rain" ], sound.reload.tags.pluck(:name)
  end

  test "feed lists in-use tags with counts and filters by a tag" do
    log_in
    post sounds_path, params: { sound: { title: "Rainy", audio: @audio, new_tag_names: "rain" } }
    post sounds_path, params: { sound: { title: "Windy", audio: @audio, new_tag_names: "wind" } }
    rainy = Sound.find_by!(title: "Rainy")
    reset!

    # The global tag list shows each in-use tag with its count.
    get root_path
    assert_response :success
    assert_select "a[href=?]", root_path(tag: "rain"), text: /rain/

    # Filtering narrows the feed to sounds carrying that tag.
    get root_path(tag: "rain")
    assert_response :success
    assert_select "a[href=?]", sound_path(rainy), text: "Rainy"
    assert_select "a", text: "Windy", count: 0
    assert_select "a", text: "Clear filter"
  end

  test "filtering by an unknown tag yields no sounds" do
    log_in
    post sounds_path, params: { sound: { title: "Solo", audio: @audio, new_tag_names: "rain" } }
    reset!

    get root_path(tag: "nonexistent")
    assert_response :success
    assert_select "a", text: "Solo", count: 0
  end
end
