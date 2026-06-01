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

A [`Dockerfile`](Dockerfile) is included for building a production container
image. Provide a persistent volume for SQLite and Active Storage, and set
`ADMIN_EMAIL`, `ADMIN_PASSWORD`, and `RAILS_MASTER_KEY` in the container
environment.

TODO: Add container-based deployment documentation.

## License

Kizuna Sound is open source software released under the MIT license, see LICENSE
in this repository.

The project name "Kizuna Sound" is not covered by the MIT license and may not be
used for forks or derivatives without permission.
