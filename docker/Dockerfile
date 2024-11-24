FROM certbot/certbot

COPY entry_point.sh /

RUN chmod +x /entry_point.sh

RUN apk add git
RUN python3 -m pip install git+https://github.com/hedger/certbot-dns-henet.git
RUN apk del git

HEALTHCHECK --interval=1m --timeout=3s --retries=5 \
  --start-period=1m --start-interval=5s \
  CMD certbot certificates --quiet || exit 1

ENTRYPOINT ["/entry_point.sh"]
