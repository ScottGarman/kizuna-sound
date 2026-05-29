# Seeds the single admin user. Idempotent: re-running will not create a duplicate
# and will not overwrite an existing admin's password.
#
# In production, set ADMIN_EMAIL and ADMIN_PASSWORD before running `bin/rails db:seed`.
# In development, the fallback credentials below are used if env vars are not set.

admin_email    = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "changeme")

if User.exists?
  puts "Admin user already exists (#{User.first.email}); skipping."
else
  User.create!(email: admin_email, password: admin_password)
  puts "Created admin user: #{admin_email}"
end
