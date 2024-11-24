FROM certbot/certbot

COPY certbot_he_auto_ep.sh /
RUN chmod +x /certbot_he_auto_ep.sh

COPY ./ /certbot-dns-he/
RUN python3 -m pip install -e /certbot-dns-he

HEALTHCHECK --interval=1m --timeout=3s --retries=5 \
  --start-period=1m --start-interval=5s \
  CMD certbot certificates --quiet || exit 1

# Disabled for compatibility with certbot/certbot
# ENTRYPOINT ["/certbot_he_auto_ep.sh"]
