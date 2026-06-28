#!/bin/sh
set -e

# Validate required credentials (no insecure defaults)
if [ -z "$ICECAST_SOURCE_PASSWORD" ]; then
  echo "ERROR: ICECAST_SOURCE_PASSWORD is not set. Aborting." >&2
  exit 1
fi
if [ -z "$ICECAST_ADMIN_PASSWORD" ]; then
  echo "ERROR: ICECAST_ADMIN_PASSWORD is not set. Aborting." >&2
  exit 1
fi
if [ -z "$ICECAST_RELAY_PASSWORD" ]; then
  echo "ERROR: ICECAST_RELAY_PASSWORD is not set. Aborting." >&2
  exit 1
fi

# Reject placeholder passwords — users must set real values in .env
for VAR in ICECAST_SOURCE_PASSWORD ICECAST_ADMIN_PASSWORD ICECAST_RELAY_PASSWORD; do
  eval VAL=\$$VAR
  if [ "$VAL" = "changeme" ]; then
    echo "ERROR: $VAR is still set to 'changeme'." >&2
    echo "  Copy .env.example to .env and set real passwords before starting." >&2
    exit 1
  fi
done

SOURCE_PASSWORD="$ICECAST_SOURCE_PASSWORD"
ADMIN_PASSWORD="$ICECAST_ADMIN_PASSWORD"
ADMIN_USERNAME="${ICECAST_ADMIN_USERNAME:-admin}"
RELAY_PASSWORD="$ICECAST_RELAY_PASSWORD"
HOSTNAME="${ICECAST_HOSTNAME:-localhost}"

# Generate Icecast configuration
cat > /etc/icecast2/icecast.xml <<EOF
<icecast>
    <location>OpenStudio</location>
    <admin>admin@localhost</admin>

    <limits>
        <clients>100</clients>
        <sources>2</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-on-connect>1</burst-on-connect>
        <burst-size>65535</burst-size>
    </limits>

    <authentication>
        <source-password>${SOURCE_PASSWORD}</source-password>
        <relay-password>${RELAY_PASSWORD}</relay-password>
        <admin-user>${ADMIN_USERNAME}</admin-user>
        <admin-password>${ADMIN_PASSWORD}</admin-password>
    </authentication>

    <hostname>${HOSTNAME}</hostname>

    <listen-socket>
        <port>8000</port>
    </listen-socket>

    <fileserve>1</fileserve>

    <paths>
        <basedir>/usr/share/icecast</basedir>
        <logdir>/var/log/icecast</logdir>
        <webroot>/usr/share/icecast/web</webroot>
        <adminroot>/usr/share/icecast/admin</adminroot>
        <alias source="/" destination="/status.xsl"/>
    </paths>

    <logging>
        <accesslog>-</accesslog>
        <errorlog>-</errorlog>
        <loglevel>3</loglevel>
        <logsize>10000</logsize>
    </logging>

    <security>
        <chroot>0</chroot>
    </security>
</icecast>
EOF

# Start Icecast in foreground
exec icecast -c /etc/icecast2/icecast.xml
