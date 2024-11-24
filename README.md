# Certbot authenticator for Hurricane Electric free DNS service (dns.he.net)

This plugin allows [certbot](https://github.com/certbot/certbot) to verify domains hosted at [dns.he.net](https://dns.he.net/) automatically using [DNS-01](https://docs.certifytheweb.com/docs/dns-validation.html) validation. During the validation process, it adds a TXT record for the domain and removes it automatically after the validation passes.

## Usage

Store the dns.he.net credentials (replace USERNAME and PASSWORD by your actual credentials):

```bash
install -m 700 -d /etc/letsencrypt/dns-credentials
install -m 600 -T /dev/null /etc/letsencrypt/dns-credentials/henet.ini
cat > /etc/letsencrypt/dns-credentials/henet.ini << "EOF"
dns_henet_username=USERNAME
dns_henet_password=PASSWORD
EOF
```

Generate a new wildcard certificate with [OCSP Must-Staple](https://scotthelme.co.uk/ocsp-must-staple/):

```bash
certbot certonly \
    --authenticator dns-henet \
    --dns-henet-credentials /etc/letsencrypt/dns-credentials/henet.ini \
    --domain '*.example.com' --domain 'example.com' \
    --must-staple
```

Renew the certificates:

```bash
certbot renew
```

## Docker Image Based on certbot

This repository also contains a Dockerfile that builds an image based on the official [certbot image](https://hub.docker.com/r/certbot/certbot/). The image is available on [Docker Hub](https://hub.docker.com/r/hedger/certbot-dns-henet/) and provides the `certbot` command with the `dns-henet` plugin pre-installed, as well as basic automation for renewing certificates.

To use the image, you can run the following command:

```bash
docker run \
    -e DOMAINS="example.com *.example.com" \
    -e EMAIL="test@example.com" \
    -v $(pwd)/henet.ini:/run/dns-credentials/henet.ini \
    -v /etc/letsencrypt:/etc/letsencrypt \
    hedger/certbot-dns-henet
```
Alternatively, you can run the `certbot` command directly:

```bash
docker run -it --rm \
    -v /etc/letsencrypt:/etc/letsencrypt \
    -v /var/lib/letsencrypt:/var/lib/letsencrypt \
    -v /var/log/letsencrypt:/var/log/letsencrypt \
    -v $(pwd)/henet.ini:/run/dns-credentials/henet.ini \
    hedger/certbot-dns-henet \
    certonly \
    --authenticator dns-henet \
    --dns-henet-credentials /run/dns-credentials/henet.ini \
    --domain '*.example.com' --domain 'example.com' \
    --must-staple
```

### Environment Variables

 * `DOMAINS`: should contain a space-separated list of domains to include in the certificate. Required.
 * `EMAIL`: should contain the email address to use for registration and recovery contact. Optional, but recommended.
 * `DAEMON`: if set to any value, the container will run in daemon mode and renew the certificate automatically. Optional.
 * `CRON_SCHEDULE`: should contain a cron schedule for renewing the certificate. Optional, default is `28 6 */2 * *`, which means once every other day.
 * `CREDENTIALS_FILE`: should contain the path to the credentials file in the container. Optional, default is `/run/dns-credentials/henet.ini`.
 * `STAGING`: if set to any value, the Let's Encrypt staging server will be used instead of the production server. Optional.
 
 **Additionally, you must provide the `henet.ini` file with your dns.he.net credentials. The file should be mounted to `$CREDENTIALS_FILE` (`/run/dns-credentials/henet.ini` by default).**

 ### Liveness Status

Container reports its status using Docker's `HEALTHCHECK` feature. It checks if the certificates are present and no other certbot process is running. That way you can set up container startup order in your orchestration system. For example, in Docker Compose you can use `depends_on`:

```yaml
services:
  certbot:
    image: hedger/certbot-dns-henet
    environment:
      DOMAINS: "example.com *.example.com"
      EMAIL: "example@example.com"
      DAEMON: 1
      CREDENTIALS_FILE: /run/secrets/he-auth
    secrets:
      - he-auth
    ...

  nginx:
    ...
    depends_on:
      certbot:
        condition: service_healthy

secrets:
  he-auth:
    file: ./he.ini
```

## Frequently Asked Questions

### Why do I need to provide the password to my he.net account?

At the moment, dns.he.net doesn't have an API for creating and removing TXT records. The only way to do it is to use web interface, and this script imitates user actions on the website. Don't worry, the script doesn't steal your credentials. It only sends the password to the dns.he.net website. You can check it by yourself: the script is less than 200 lines of code.

### Does your script parse HTML? Will it break suddenly if the website design changes?

Yes. Unfortunately, there is no better way yet, as dns.he.net doesn't have the necessary API. Luckily, the design of dns.he.net hasn't been changed for quite a long time, so there is hope that this script will work for some period of time. Anyway, it's better than nothing.

### How do I install this plugin?

If you are on Archlinux, install it from [AUR](https://aur.archlinux.org/packages/certbot-dns-henet-git/). Check out [Arch Wiki](https://wiki.archlinux.org/index.php/Arch_User_Repository#Installing_packages) for instructions, but it may be simpler and better to use an [AUR helper](https://wiki.archlinux.org/index.php/AUR_helpers).

Alternatively, you can use the PKGBUILD shipped in this repository. Check out [this Arch Wiki page](https://wiki.archlinux.org/index.php/makepkg#Usage) for the details about installing from PKGBUILD.

For other distributions and operating systems, you should be able to install this plugin using setup.py, just as any Python module. Using the package manager is preferred: many package managers offer some simple mechanism for creating packages based on setup.py. However, if you wish to install it manually (or if you need some reference installations commands for creating a package), run the following commands:


```bash
python setup.py build
python setup.py test
python setup.py install
```

Alternatively you can use `pip`:

```bash
pip install git+https://github.com/hedger/certbot-dns-henet.git
```