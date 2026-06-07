# Kizuna Sound

Kizuna Sound is an open source, self-hosted web application for sharing your
music or sound creations. *Kizuna* (絆) is a Japanese word meaning "bond" or
"connection". Kizuna Sound celebrates the emotional bonds we create by sharing
our sonic creations.

Use it to host and share your music, field recordings, spoken word, or whatever
sounds you like.

As of June 2026, Kizuna Sound is under active development and is in an early
alpha state. Expect many changes to the feature set and look and feel.

## Features

- Upload and play audio files - supports mp3/wav/flac audio formats
- View a blog-style feed of your sounds
- The waveform display and in-browser playback is powered by
  [wavesurfer.js](https://wavesurfer.xyz/), with play/pause, a time readout, and
  playback-speed control
- Tag your sounds and allow visitors to filter the feed by tag
- A single admin account manages uploads; the feed and players are public-facing
- Customizable site settings (title, about blurb, custom links, heading/banner
  image, tag visibility)

What Kizuna Sound *doesn't* do:

- Multi-user accounts
- Likes, comments
- Collections
- Embedded player for third-party sites

I created this to be an intentionally simple webapp for sharing your own music, not
creating a social network or Bandcamp clone.

## Technology Stack

- [Ruby on Rails](https://rubyonrails.org/) 8.1 (Ruby 4.0)
- SQLite via Active Record
- [Active Storage](https://guides.rubyonrails.org/active_storage_overview.html)
  for audio file storage
- Hotwire (Turbo + Stimulus) with [importmap-rails](https://github.com/rails/importmap-rails)
- [Tailwind CSS](https://github.com/rails/tailwindcss-rails)
- [wavesurfer.js](https://wavesurfer.xyz/) for waveform rendering

This source code was created with assistance from AI tools, but every line of code
has been personally reviewed and understood by a human maintainer.

## Getting Started

### Prerequisites

- Ruby 4.0.3 (see [`.ruby-version`](.ruby-version))
- SQLite 3

### Setup

```bash
bundle install
bin/rails db:prepare   # create, load schema, and seed
```

The admin account is seeded from environment variables. Set these before running
the seed in any non-development environment:

```bash
export ADMIN_EMAIL=you@example.com
export ADMIN_PASSWORD=a-strong-password
bin/rails db:seed
```

If unset, development falls back to `admin@example.com` / `changeme` — change
these before deploying to a public-facing site!

### Running the app

```bash
bin/dev
```

Then visit <http://localhost:3000>. Log in with your admin credentials to upload
sounds and configure settings.

## Running the tests

```bash
bin/rails test
```

## Deployment

Kizuna Sound deploys as a Docker container using [Kamal](https://kamal-deploy.org/).
Container images are built by GitHub Actions and published to the GitHub Container
Registry (GHCR); Kamal pulls those images and runs them on your server.

### How images are built

[`.github/workflows/build.yml`](.github/workflows/build.yml) builds the image
from the [`Dockerfile`](Dockerfile) and pushes it to
`ghcr.io/scottgarman/kizuna-sound` on every merge to `main` (and on `v*` tags).
Each build is tagged with the commit SHA (`sha-<commit>`), plus `latest` on
`main` and a semver tag for releases. The package is public, so it can be pulled
without authentication.

### Persistent storage (important)

All application state — the SQLite database, Solid Queue/Cache/Cable, and every
uploaded audio file — lives under `storage/`. `config/deploy.yml` mounts this as
a named volume (`kizuna_sound_storage:/rails/storage`) so it survives container
replacement. **Back this volume up off-server**; losing it means losing the
database and all uploads.

### One-time setup

1. Set your server host(s) in [`config/deploy.yml`](config/deploy.yml) under
   `servers:`.
2. Create a fine-grained GitHub PAT with `read:packages`. **Do not paste it into
   `.kamal/secrets`** — that file is committed to git. Instead export it in your
   environment (`export KAMAL_REGISTRY_PASSWORD=...`, or use a password manager)
   and reference it in `.kamal/secrets` with `KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD`,
   matching how `RAILS_MASTER_KEY` is already referenced there.
3. Ensure `config/master.key` exists locally (`.kamal/secrets` reads
   `RAILS_MASTER_KEY` from it).
4. Provision the server and deploy for the first time:

   ```bash
   bin/kamal setup
   ```

5. Seed the admin account on the server (one time):

   ```bash
   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=a-strong-password \
     bin/kamal app exec "bin/rails db:seed"
   ```

### Deploying updates

After a merge to `main` has built a new image, deploy it from a clean checkout
of that commit:

```bash
git checkout main && git pull
bin/kamal deploy --skip-push   # pull the CI-built image and run it
```

`--skip-push` tells Kamal to use the image already in GHCR rather than rebuilding
locally; it pulls the image tagged with the current commit SHA. Deploy from a
clean working tree so the SHA matches what CI published.

Other useful commands: `bin/kamal rollback` (revert to the previous image),
`bin/kamal app logs -f`, and `bin/kamal console`.

## License

Kizuna Sound is open source software released under the MIT license, see LICENSE
in this repository.

The project name "Kizuna Sound" is not covered by the MIT license and may not be
used for forks or derivatives without permission.
