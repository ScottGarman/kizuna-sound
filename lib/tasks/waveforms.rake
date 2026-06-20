namespace :sounds do
  desc "Enqueue waveform generation for sounds missing cached peaks (backfill)"
  task backfill_waveforms: :environment do
    scope = Sound.where(waveform_peaks: nil)
    total = scope.count
    puts "Enqueuing GenerateWaveformJob for #{total} sound(s) without cached peaks..."

    scope.find_each do |sound|
      GenerateWaveformJob.perform_later(sound.id)
    end

    puts "Done. Jobs will run via Solid Queue."
  end
end
