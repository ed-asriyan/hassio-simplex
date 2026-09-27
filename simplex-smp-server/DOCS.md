# Home Assistant Add-on: SimpleX SMP Server

> [!WARNING]
> Run the addon carefully on residential IP addresses!
> It is recommended to enable a password so only you or people you trust can use your server, instead of leaving it open to random users. Otherwise strangers may use it to relay encrypted messages or files, including traffic you would not want associated with your IP address, even though the traffic relayed through and stored on the server remains encrypted.

## How to use
1. (optional) Setup dynamic DNS instead of relying on a changing residential IP. [Duck DNS add-on](https://www.home-assistant.io/integrations/duckdns) is a practical option.
2. Open the **Configuration** tab and fill in the options (see below).
3. Under **Network**, set the host port to the same value as the `port` option.
4. If Home Assistant is behind NAT, ensure that the port is forwarded from your router.
5. Save and start the addon.
6. Open **Log** and find the printed server address. Copy it into your SimpleX Chat app.

## Options
| Option | Required | Default | Description  |
| ------ | -------- | ------- | ------------ |
| `addr` | Yes | | Public domain or IP of your server. Example: `smp1.example.com` or `1.2.3.4`. |
| `port` | Yes | `5223` | Port the server listens on. **Must match** the host port set in the Network section. |
| `pass` | No | | Password required to create new queues. The address format becomes `smp://fingerprint:password@host`. |
| `new_queues` | Yes | `true` | Allow creating new messaging queues. Set to `false` to decommission the server while existing connections continue to work. |
| `restore_messages` | Yes | `true` | Save and restore undelivered messages across server restarts |
| `expire_messages_days` | Yes | `21` | Automatically delete undelivered messages after this many days. |
| `expire_ntfs_hours` | Yes | `24` | Automatically delete undelivered notifications after this many hours. |
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
