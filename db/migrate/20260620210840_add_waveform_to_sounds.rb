class AddWaveformToSounds < ActiveRecord::Migration[8.1]
  def change
    # Cached so the feed can draw each waveform without the browser downloading
    # and decoding the full audio file. Populated asynchronously by
    # GenerateWaveformJob; both stay nil until that runs (the player falls back
    # to fetching the audio in the meantime).
    add_column :sounds, :duration, :float
    add_column :sounds, :waveform_peaks, :json
  end
end
