# Computes and caches a sound's waveform peaks and duration off the request
# cycle. Enqueued by Sound whenever its audio is attached or replaced.
class GenerateWaveformJob < ApplicationJob
  queue_as :default

  # The sound (or its audio) may be gone by the time the job runs; nothing to do.
  discard_on ActiveRecord::RecordNotFound

  def perform(sound_id)
    sound = Sound.find(sound_id)
    return unless sound.audio.attached?

    # blob.open downloads the audio to a tempfile and cleans it up afterward.
    sound.audio.blob.open do |file|
      result = WaveformExtractor.call(file.path)
      # update_columns skips validations and callbacks, so this write neither
      # regenerates the slug nor re-enqueues this job.
      sound.update_columns(waveform_peaks: result.peaks, duration: result.duration)
    end
  end
end
