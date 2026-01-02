#!/usr/bin/env bash
set -euo pipefail

# Initialize a local PostgreSQL instance for development
# This script is meant to be run from within nix-shell

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
POSTGRES_DIR="$PROJECT_DIR/.postgres"
PGDATA="$POSTGRES_DIR/data"
PGHOST="$POSTGRES_DIR"
LOGFILE="$POSTGRES_DIR/postgres.log"

mkdir -p "$POSTGRES_DIR"

if [ ! -d "$PGDATA" ]; then
    echo "Initializing PostgreSQL database cluster..."
    initdb -D "$PGDATA" --auth=trust --no-locale --encoding=UTF8

    # Configure for local socket connections
    cat >> "$PGDATA/postgresql.conf" <<EOF
unix_socket_directories = '$PGHOST'
listen_addresses = ''
EOF

    echo "Database cluster initialized at $PGDATA"
fi

echo ""
echo "To start PostgreSQL:"
echo "  pg_ctl -D $PGDATA -l $LOGFILE start"
echo ""
echo "To stop PostgreSQL:"
echo "  pg_ctl -D $PGDATA stop"
echo ""
echo "To connect:"
echo "  psql -h $PGHOST -d postgres"
echo ""
echo "Environment variables for Rails (add to .env or export):"
echo "  export GLOWFIC_DATABASE_PEER=1"
echo "  export PGHOST=$PGHOST"
echo ""
