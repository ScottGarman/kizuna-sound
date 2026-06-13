require "test_helper"

class SoundTest < ActiveSupport::TestCase
  def build_sound(title:)
    sound = users(:admin).sounds.build(title: title)
    sound.audio.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.wav")),
      filename: "sample.wav",
      content_type: "audio/wav"
    )
    sound
  end

  test "generates a slug from the title on create" do
    sound = build_sound(title: "Midnight Rain Improv")
    sound.save!
    assert_equal "midnight-rain-improv", sound.slug
  end

  test "to_param uses the slug so the database id is never exposed" do
    sound = build_sound(title: "Foggy Morning")
    sound.save!
    assert_equal "foggy-morning", sound.to_param
    refute_match(/\A\d+\z/, sound.to_param)
  end

  test "disambiguates slugs when two sounds share a title" do
    first = build_sound(title: "Same Name")
    first.save!
    second = build_sound(title: "Same Name")
    second.save!
    assert_equal "same-name", first.slug
    assert_not_equal first.slug, second.slug
    assert second.slug.start_with?("same-name")
  end

  test "regenerates the slug when the title changes" do
    sound = build_sound(title: "Original Title")
    sound.save!
    sound.update!(title: "Brand New Title")
    assert_equal "brand-new-title", sound.slug
  end

  test "old slugs still resolve after a title change (history)" do
    sound = build_sound(title: "First Title")
    sound.save!
    sound.update!(title: "Second Title")

    assert_equal sound, Sound.friendly.find("second-title")
    assert_equal sound, Sound.friendly.find("first-title")
  end
end
