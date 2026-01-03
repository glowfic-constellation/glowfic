# Nix development shell for Glowfic
#
# Usage:
#   nix-shell              # Enter the shell manually
#
# For direnv users, create a .envrc file with:
#   echo "use nix" > .envrc
#   direnv allow
#
{
  pkgs ? import (fetchTarball {
    # nixpkgs-unstable - latest for Ruby 3.4.x
    url = "https://github.com/NixOS/nixpkgs/archive/76eec3925eb9bbe193934987d3285473dbcfad50.tar.gz";
    sha256 = "12ifsbmygs4wp1bifaknk2p9gdy203mjzjidi77vl61w0hbnhflh";
  }) {}
}:

let
  # Ruby 3.4.x
  ruby = pkgs.ruby_3_4;

  # Chrome path - only evaluated on Linux
  chromePath = if pkgs.stdenv.isLinux then "${pkgs.chromium}/bin/chromium" else "";
in
pkgs.mkShell {
  buildInputs = [
    # Ruby
    ruby

    # Node.js for asset pipeline and linting
    pkgs.nodejs_22

    # PostgreSQL client and server for local dev
    pkgs.postgresql_16

    # Redis for background jobs
    pkgs.redis

    # Native gem dependencies
    pkgs.libxml2
    pkgs.libxslt
    pkgs.zlib
    pkgs.libyaml
    pkgs.openssl

    # For native gem compilation
    pkgs.pkg-config
    pkgs.gnumake
    pkgs.gcc

    # Git and GitHub CLI
    pkgs.git
    pkgs.gh
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    # Chrome/Chromium for system tests (Linux only)
    pkgs.chromium
  ];

  shellHook = ''
    # Set up gem installation to local directory
    export GEM_HOME="$PWD/.gems"
    export PATH="$GEM_HOME/bin:$PATH"
    mkdir -p "$GEM_HOME"

    # PostgreSQL configuration for local development
    export PGDATA="$PWD/.postgres/data"
    export PGHOST="$PWD/.postgres"
    export GLOWFIC_DATABASE_PEER=1
    export GLOWFIC_DATABASE_USER="$(whoami)"

    # For pg gem - ensure pg_config is in PATH
    export PATH="${pkgs.postgresql_16}/bin:$PATH"

    # For Chrome/Selenium tests
    # On macOS, use system Chrome; on Linux, use nix chromium
    if [[ "$(uname)" == "Darwin" ]]; then
      export CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    else
      export CHROME_BIN="${chromePath}"
    fi
    export PUPPETEER_EXECUTABLE_PATH="$CHROME_BIN"

    # Bundler config for native extensions
    bundle config build.pg --with-pg-config=${pkgs.postgresql_16}/bin/pg_config 2>/dev/null || true
    bundle config build.nokogiri --use-system-libraries 2>/dev/null || true

    echo ""
    echo "Glowfic development shell"
    echo "========================="
    echo "Ruby: $(ruby --version)"
    echo "Node: $(node --version)"
    echo "PostgreSQL: $(psql --version)"
    echo ""

    # First-time setup detection and auto-run
    if [ ! -f "$GEM_HOME/bin/rails" ]; then
      echo "First-time setup detected. Running bundle install..."
      bundle install
    fi

    if [ ! -d "$PGDATA" ]; then
      echo "Initializing PostgreSQL..."
      ./scripts/init-postgres.sh
    fi

    # Start PostgreSQL if not running
    if ! pg_ctl status >/dev/null 2>&1; then
      echo "Starting PostgreSQL..."
      pg_ctl start -l .postgres/postgres.log -w
    fi

    # Start Redis if not running
    if ! redis-cli ping >/dev/null 2>&1; then
      echo "Starting Redis..."
      redis-server --daemonize yes
    fi

    # Create databases if they don't exist
    if ! psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw glowfic_dev; then
      echo "Creating development database..."
      createdb glowfic_dev
      echo "Running migrations..."
      bundle exec rails db:migrate
    fi

    if ! psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw glowfic_test; then
      echo "Creating test database..."
      createdb glowfic_test
      echo "Loading test schema..."
      RAILS_ENV=test bundle exec rails db:schema:load
    fi

    echo ""
    echo "Ready! Services running."
    echo "  rails server        # run dev server"
    echo "  bundle exec rspec   # run tests"
    echo "  pg_ctl stop         # stop PostgreSQL"
    echo ""
  '';

  # Environment variables
  LANG = "en_US.UTF-8";
  # Don't set RAILS_ENV - let rspec and rails set it appropriately
}
