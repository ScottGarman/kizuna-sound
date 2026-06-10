# Production customizations kept out of the stock config/environments/production.rb so
# that framework upgrades to that file stay conflict-free. Loaded from the bottom of
# production.rb. Settings here run after the stock block, so they take precedence.
#
# This file IS committed and baked into the image at build time, so keep it generic:
# deployment-specific values are driven by ENV that Kamal injects at runtime (see the
# env block in your Kamal destination file, e.g. config/deploy.<dest>.yml).
Rails.application.configure do
  # When the app runs behind a TLS-terminating reverse proxy (kamal-proxy or your own
  # nginx), set RAILS_ASSUME_SSL=true so Rails treats requests as HTTPS (secure cookies,
  # https URL helpers) and RAILS_FORCE_SSL=true for HSTS + secure-cookie enforcement.
  # force_ssl won't cause a redirect loop because assume_ssl already makes request.ssl? true.
  config.assume_ssl = ENV["RAILS_ASSUME_SSL"] == "true"
  config.force_ssl  = ENV["RAILS_FORCE_SSL"] == "true"
end
