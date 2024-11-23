FROM certbot/certbot

COPY entry_point.sh /

RUN chmod +x /entry_point.sh

RUN apk add git
RUN python3 -m pip install git+https://github.com/hedger/certbot-dns-henet.git
RUN apk del git

ENTRYPOINT ["/entry_point.sh"]
