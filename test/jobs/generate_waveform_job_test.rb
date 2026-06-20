require "test_helper"

class GenerateWaveformJobTest < ActiveJob::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @admin = users(:admin)
  end

  test "caches peaks and duration on the sound" do
    sound = @admin.sounds.create!(
      title: "Job target",
      audio: fixture_file_upload("sample.wav", "audio/wav")
    )
    sound.update_columns(waveform_peaks: nil, duration: nil)

    GenerateWaveformJob.perform_now(sound.id)

    sound.reload
    assert_not_nil sound.duration
    assert_kind_of Array, sound.waveform_peaks
  end

  test "is discarded when the sound no longer exists" do
    assert_nothing_raised do
      GenerateWaveformJob.perform_now(-1)
    end
  end
end
