require "test_helper"
require "open3"

class WaveformExtractorTest < ActiveSupport::TestCase
  # A 1-second 440 Hz tone gives us real, non-silent audio to measure without
  # committing a binary fixture. Requires ffmpeg, which the test image installs.
  def with_tone(seconds: 1, &block)
    Tempfile.create([ "tone", ".wav" ]) do |file|
      system("ffmpeg", "-v", "error", "-y",
             "-f", "lavfi", "-i", "sine=frequency=440:duration=#{seconds}",
             file.path, exception: true)
      block.call(file.path)
    end
  end

  test "extracts normalized peaks and a duration from a real tone" do
    with_tone(seconds: 1) do |path|
      result = WaveformExtractor.call(path)

      assert_in_delta 1.0, result.duration, 0.05
      assert_equal WaveformExtractor::PEAK_COUNT, result.peaks.length
      # A steady tone never falls silent, so every bucket's peak is normalized
      # into 0.0–1.0 and is comfortably above zero.
      assert result.peaks.all? { |p| p >= 0.0 && p <= 1.0 }, "peaks must be normalized to 0..1"
      assert result.peaks.all? { |p| p > 0.05 }, "a steady tone should be loud in every bucket"
    end
  end

  test "collapses very short audio into however many buckets it can fill" do
    with_tone(seconds: 0.01) do |path|
      result = WaveformExtractor.call(path)

      assert_operator result.peaks.length, :<=, WaveformExtractor::PEAK_COUNT
      assert_operator result.peaks.length, :>, 0
    end
  end

  test "raises when ffmpeg cannot decode the input" do
    Tempfile.create([ "junk", ".wav" ]) do |file|
      file.write("not actually audio")
      file.flush

      assert_raises(WaveformExtractor::ExtractionError) do
        WaveformExtractor.call(file.path)
      end
    end
  end
end
