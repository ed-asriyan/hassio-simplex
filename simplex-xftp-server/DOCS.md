# Home Assistant Add-on: SimpleX XFTP Server

> [!WARNING]
> Run the addon carefully on residential IP addresses!
> It is recommended to enable a password so only you or people you trust can use your server, instead of leaving it open to random users. Otherwise strangers may use it to relay encrypted messages or files, including traffic you would not want associated with your IP address, even though the traffic relayed through and stored on the server remains encrypted.

## How to use
1. (optional) Setup dynamic DNS instead of relying on a changing residential IP. [Duck DNS add-on](https://www.home-assistant.io/integrations/duckdns) is a practical option.
2. (optional) Set up SSL for the server information page, see [SSL](#ssl-optional).
3. Open the **Configuration** tab and fill in the options (see below).
4. Under **Network**, set the host port to the same value as the `port` option.
5. If Home Assistant is behind NAT, ensure that the port is forwarded from your router.
6. Save and start the addon.
7. Open **Log** and find the printed server address. Copy it into your SimpleX Chat app.

## Options
| Option | Required | Default | Description  |
| ------ | -------- | ------- | ------------ |
| `addr` | Yes | | Public domain or IP of your server. Example: `xftp1.example.com` or `1.2.3.4`. |
| `port` | Yes | `443` | Port the server listens on. **Must match** the host port set in the Network section. |
| `quota` | Yes | `10gb` | Total disk quota for stored files. Format: `10gb`, `100gb`, etc. |
| `pass` | No | | Password required to upload files. Shared only with upload-authorized users. The address format becomes `xftp://fingerprint:password@host`. |
| `expire_files_hours` | Yes | `48` | Automatically delete files after this many hours. |
| `new_files` | Yes | `true` | Allow uploading new files. Set to `false` to decommission the server while still allowing downloads of existing files. |
| `ssl` | No | disabled | Optional HTTPS for the server information page. See [SSL](#ssl-optional). |
| `information` | No | | Optional public information about who operates the server. See [Server information](#server-information). |

### Server information
Public information about who operates the server. It is written to the `[INFORMATION]` section of the server configuration. All fields are optional: leave a field empty to omit it.

| Field | Description |
| ----- | ----------- |
| `server_country` | Country where the server is located, as an [ISO 3166](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) 2-letter code, e.g. `DE`. |
| `operator` | Name of the organization or person operating the server. |
| `operator_country` | Country of the operator, as an ISO 3166 2-letter code. |
| `website` | Website of the operator, e.g. `https://example.com`. |
| `admin_email` | Email for administrative contacts. |
| `complaints_email` | Email for complaints and feedback. |
| `hosting` | Name of the hosting provider, e.g. your own name when self-hosting at home. |
| `hosting_country` | Country of the hosting provider, as an ISO 3166 2-letter code. |
| `hosting_type` | `virtual` (VPS), `dedicated` (rented physical server), `colocation` (own server in a data center) or `owned` (own server at own premises, e.g. Home Assistant at home). |

The `source_code` field required by the AGPLv3 license is always set to `https://github.com/simplex-chat/simplexmq`.

## SSL (optional)
SSL is **off** by default and is not required for SimpleX to work: SimpleX apps check your server by its fingerprint, not by this certificate. SSL only makes the server information page (`https://xftp1.example.com`) open in a browser without warnings.

If you want SSL, do the following. Every step matters.

### Step 1. Install the Let's Encrypt app
1. In Home Assistant open **Settings → Apps** and open the app store.
2. Find the official **Let's Encrypt** app and click **Install**.

### Step 2. Configure the Let's Encrypt app
Open the **Configuration** tab of the Let's Encrypt app, click **⋮ → Edit in YAML** and paste this, replacing the domain and the email with yours:

```yaml
domains:
  - xftp1.example.com
email: you@example.com
keyfile: privkey.pem
certfile: fullchain.pem
challenge: http
key_type: rsa
```

What each line means:
- `domains` — must contain exactly the same domain as the `addr` option of this addon. If you already have other domains there (e.g. for Home Assistant itself), just add one more line.
- `email` — your email, Let's Encrypt sends expiration notices there.
- `keyfile` / `certfile` — file names in the `/ssl` folder. Remember them: you will type the same names in this addon.
- `challenge: http` — Let's Encrypt checks that you own the domain by connecting to port `80`. Forward port `80` on your router to Home Assistant. If you can't, use `challenge: dns` (see the Let's Encrypt app documentation).
- `key_type: rsa` — **the key type is important.** XFTP server accepts RSA certificates (any size) and ECDSA P-256 certificates. `key_type: rsa` is the simplest choice. If you prefer `key_type: ecdsa`, also add `elliptic_curve: secp256r1`: without it the Let's Encrypt app uses P-384, which XFTP server does not support.

Click **Save**, then **Start**. Open the **Log** tab of the Let's Encrypt app and wait until it says the certificate was issued. The app stops by itself after that: this is normal.

### Step 3. Renew the certificate automatically
The Let's Encrypt app renews the certificate only when it is started. Create an automation that starts it every night: **Settings → Automations & scenes → Create automation → ⋮ → Edit in YAML**, paste and save:

```yaml
alias: Renew Let's Encrypt certificate
triggers:
  - trigger: time
    at: "03:00:00"
actions:
  - action: hassio.addon_restart
    data:
      addon: core_letsencrypt
```

This addon notices a renewed certificate within an hour and restarts the server by itself.

### Step 4. Enable SSL in this addon
Open the **Configuration** tab of this addon and expand the **SSL** section:
- **Enable SSL** — turn on.
- **Public certificate** — the same value as `certfile` in the Let's Encrypt app (`fullchain.pem`).
- **Private key** — the same value as `keyfile` in the Let's Encrypt app (`privkey.pem`).

Or in YAML:

```yaml
ssl:
  enabled: true
  certfile: fullchain.pem
  keyfile: privkey.pem
```

The page is served on the same `port` as the XFTP protocol.

Save and restart this addon. If something is wrong with the certificate, the **Log** tab shows a `WARNING` explaining what to fix, and the server keeps working without the HTTPS page.
