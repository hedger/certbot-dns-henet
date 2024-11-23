#!/bin/sh

# Enable strict mode
set -euo pipefail


check_and_set_env() {
    RSA_KEY_SIZE=${RSA_KEY_SIZE:-4096}
    STAGING=${STAGING:-}
    DOMAINS=${DOMAINS:-}
    EMAIL=${EMAIL:-}
    CRON_SCHEDULE=${CRON_SCHEDULE:-28 6 */2 * *}
    DAEMON=${DAEMON:-}

    STAGING_PARAMETER=""
    if [ -z "$STAGING" ]; then
        STAGING_PARAMETER="--staging"
    fi

    if [ -z "$DOMAINS" ]; then
        echo "Please set DOMAINS environment variable"
        exit 1
    fi

    if [ ! -e "/etc/letsencrypt/dns-credentials/henet.ini" ]; then
        echo "Please mount Hurricane Electric DNS credentials to /etc/letsencrypt/dns-credentials/henet.ini"
        echo "See https://github.com/hedger/certbot-dns-henet for more information"
        exit 1
    fi
}

check_and_set_env

# Setup cron schedule
echo "$CRON_SCHEDULE root /usr/local/bin/certbot renew" > /tmp/certbot-cron
crontab /tmp/certbot-cron
rm /tmp/certbot-cron

did_issue_cert=0

if [ -d "/etc/letsencrypt/live/" ]; then
    echo "Initial issue has already been completed"
    echo "Live certificates:"
    echo $(ls "/etc/letsencrypt/live/" | grep -v README)
    echo
else
    domain_args=""
    for domain in $DOMAINS; do
        domain_args="$domain_args -d $domain"
    done

    if [ -z "$EMAIL" ]; then
        email_arg="--register-unsafely-without-email"
    else
        email_arg="--email $EMAIL"
    fi

    certbot certonly \
        --non-interactive \
        -a dns-henet \
        --dns-henet-credentials /etc/letsencrypt/dns-credentials/henet.ini \
        $STAGING_PARAMETER \
        $email_arg \
        $domain_args \
        --rsa-key-size $RSA_KEY_SIZE \
        --agree-tos \
        --force-renewal

    did_issue_cert=1
fi

if [ "$did_issue_cert" -eq 1 ]; then
    echo "Certificate has been issued"
else
    echo "Certificate has already been issued. Attempting to renew"
    certbot renew
fi

if [ -z "$DAEMON" ]; then
    echo "Exiting because DAEMON is not set"
    exit 0
fi

echo "Running cron job. Effective schedule: $(crontab -l | grep -v '^#')"
# Run cron in the foreground
crond -f
