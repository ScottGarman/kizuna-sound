require "open3"

# Turns an audio file into the small, JSON-serializable data the waveform player
# needs to render without downloading the whole file: a list of normalized
# amplitude peaks (0.0–1.0) plus the track duration in seconds.
#
# ffmpeg decodes any of our accepted formats (.wav/.mp3/.flac) to raw mono PCM,
# downsampled to SAMPLE_RATE since we only need the silhouette, not fidelity.
# We then collapse those samples into PEAK_COUNT buckets, taking the loudest
# sample in each. ffmpeg must be on PATH (installed in the Dockerfile and CI).
class WaveformExtractor
  # Resolution of the stored waveform. ~500 peaks is plenty for the feed and the
  # show page while keeping each sound's JSON down to a few KB.
  PEAK_COUNT = 500
  # We only need amplitude over time, so an 8 kHz mono stream is more than enough
  # and keeps the decoded buffer small even for long recordings.
  SAMPLE_RATE = 8_000
  # 16-bit signed samples range over ±32768.
  MAX_AMPLITUDE = 32_768.0

  Result = Struct.new(:peaks, :duration, keyword_init: true)

  class ExtractionError < StandardError; end

  def self.call(path) = new(path).call

  def initialize(path)
    @path = path.to_s
  end

  def call
    Result.new(peaks: extract_peaks, duration: extract_duration)
  end

  private

  def extract_peaks
    samples = decode_samples
    return [] if samples.empty?

    bucket_size = (samples.length.to_f / PEAK_COUNT).ceil
    samples.each_slice(bucket_size).map do |bucket|
      (bucket.max_by(&:abs).abs / MAX_AMPLITUDE).round(3)
    end
  end

  # Raw little-endian signed 16-bit mono PCM on stdout, which we unpack to an
  # array of integer samples. stderr is captured (not leaked to the log) and
  # surfaced in the error when ffmpeg can't read the file.
  def decode_samples
    stdout, stderr, status = Open3.capture3(
      "ffmpeg", "-v", "error", "-i", @path,
      "-ac", "1", "-ar", SAMPLE_RATE.to_s,
      "-f", "s16le", "-acodec", "pcm_s16le", "-",
      binmode: true
    )
    raise ExtractionError, "ffmpeg failed to decode #{@path}: #{stderr.strip}" unless status.success?

    stdout.unpack("s<*")
  end

  def extract_duration
    stdout, status = Open3.capture2(
      "ffprobe", "-v", "error",
      "-show_entries", "format=duration",
      "-of", "default=noprint_wrappers=1:nokey=1", @path
    )
    status.success? ? stdout.strip.to_f : nil
  end
end
