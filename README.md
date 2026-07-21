# NetBird for OpenWrt 24.10 — Xiaomi AC2100

This project packages the upstream NetBird peer client for the OpenWrt 24.10 release line on the Xiaomi AC2100 family.

## Target matrix

| Item | Value |
| --- | --- |
| OpenWrt releases | `24.10.0` through `24.10.7` |
| Target/subtarget | `ramips/mt7621` |
| Default profile | `xiaomi_mi-router-ac2100` |
| Also relevant profile | `xiaomi_redmi-router-ac2100` |
| OpenWrt package arch | `mipsel_24kc` |
| NetBird version source of truth | `package/netbird/Makefile` |
| Release tag format | `netbird-<netbird-version>-r<package-release>-openwrt-24.10` |

The package uses the upstream prebuilt `linux/mipsle soft-float` NetBird binary, which matches the ramips/mt7621 little-endian MIPS target class used by Xiaomi AC2100 OpenWrt images.

NetBird version, package release, source asset, and source hash are intentionally not pinned in this README. They are defined in `package/netbird/Makefile` and updated by `scripts/update-netbird-version.sh` / the scheduled GitHub Actions release watcher.

The service layout deliberately follows the official OpenWrt `netbird` package where it matters for recent profile-based NetBird releases: persistent profile state under `/root/.config/netbird`, SSH config writes disabled on OpenWrt/dropbear systems, and DNS state kept under `/var/lib/netbird` to reduce flash wear.

## Why not the official OpenWrt package?

OpenWrt 24.10 currently carries an older NetBird package in the official feeds. Recent NetBird releases require a newer Go toolchain than the OpenWrt 24.10 SDK provides for source builds, so this project packages the upstream prebuilt `linux/mipsle soft-float` binary while keeping OpenWrt-style service defaults.

## Files

```text
package/netbird/Makefile              OpenWrt package definition and NetBird version metadata
package/netbird/files/netbird.init    procd init script
package/netbird/files/netbird.config  UCI defaults
scripts/build-sdk.sh                  reproducible SDK build helper
scripts/update-netbird-version.sh     helper to bump to latest NetBird release
```

## Host prerequisites

On Debian/Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential ca-certificates curl file gawk gettext git jq \
  libncurses-dev python3 rsync unzip wget zstd
```

## Build

From the project root, build the default OpenWrt release configured by `scripts/build-sdk.sh`:

```sh
./scripts/build-sdk.sh
```

To build for a specific OpenWrt 24.10 point release:

```sh
OPENWRT_VERSION=24.10.7 ./scripts/build-sdk.sh
```

The 24.10 matrix currently covers:

```text
24.10.0
24.10.1
24.10.2
24.10.3
24.10.4
24.10.5
24.10.6
24.10.7
```

The output `.ipk` will be under the SDK `bin/packages/...` directory printed by the script.

To target Redmi AC2100 profile metadata validation instead:

```sh
PROFILE=xiaomi_redmi-router-ac2100 OPENWRT_VERSION=24.10.7 ./scripts/build-sdk.sh
```

The package itself is architecture-specific rather than image-profile-specific, but the profile check prevents accidentally building against the wrong OpenWrt target.

For SDK archives with a different toolchain suffix, override the SDK basename explicitly:

```sh
SDK_BASENAME=openwrt-sdk-24.10.7-ramips-mt7621_gcc-13.3.0_musl.Linux-x86_64 OPENWRT_VERSION=24.10.7 ./scripts/build-sdk.sh
```

## Download prebuilt packages

Prebuilt `.ipk` artifacts are published under GitHub Releases:

https://github.com/hermes-jarvis-bot/netbird-openwrt-xiaomi-ac2100/releases

Choose the aggregate release for the OpenWrt 24.10 line. Release tags follow this format:

```text
netbird-<netbird-version>-r<package-release>-openwrt-24.10
```

Each aggregate release includes eight explicitly version-labelled assets, one built with each matching SDK:

```text
netbird_<netbird-version>-r<package-release>_mipsel_24kc-openwrt-24.10.0.ipk
...
netbird_<netbird-version>-r<package-release>_mipsel_24kc-openwrt-24.10.7.ipk
```

Download the asset whose `openwrt-<version>` suffix exactly matches the firmware on the router. Always verify it using the `SHA256SUMS` asset from the same GitHub Release.

## Install on router

Copy the generated or downloaded `.ipk` to the router and install it:

```sh
opkg update
opkg install ca-bundle kmod-wireguard
opkg install ./netbird_<netbird-version>-r<package-release>_mipsel_24kc.ipk
```

Use package feeds matching the exact OpenWrt version running on the router, especially for kernel packages such as `kmod-wireguard`.

## Configure

Create a setup-key file. Do not place secrets directly in shell history if you can avoid it.

```sh
install -d -m 700 /etc/netbird
printf '%s\n' 'PASTE_SETUP_KEY_HERE' > /etc/netbird/setup.key
chmod 600 /etc/netbird/setup.key
```

Enable the service:

```sh
uci set netbird.main.enabled='1'
uci set netbird.main.hostname='xiaomi-ac2100'
uci commit netbird
/etc/init.d/netbird enable
/etc/init.d/netbird start
```

For a self-hosted NetBird control plane:

```sh
uci set netbird.main.management_url='https://api.example.com:443'
uci set netbird.main.admin_url='https://app.example.com:443'
uci commit netbird
/etc/init.d/netbird restart
```

## Verify on router

```sh
logread -f -e netbird
netbird status --daemon-addr unix:///var/run/netbird.sock
ip link show | grep -E 'wt|netbird|wireguard'
```

## GitHub Actions automation

- `Build OpenWrt package` runs a matrix build for OpenWrt `24.10.0` through `24.10.7`.
- `Check NetBird release and publish package` performs one hourly preflight against the latest upstream NetBird release.
- If the aggregate release already exists, the protocol exits before any OpenWrt SDK download or matrix build.
- For a new NetBird version, it builds the `24.10.0`–`24.10.7` matrix and publishes one GitHub Release for the complete OpenWrt 24.10 line:

```text
netbird-<netbird-version>-r<package-release>-openwrt-24.10
```

## Operational notes

- The service is disabled by default; installation alone will not join the router to a NetBird network.
- The setup key is read from `/etc/netbird/setup.key` by default and should be mode `0600`.
- The default profile/state directory is `/root/.config/netbird`, matching the official OpenWrt package for modern NetBird profile support.
- `NB_DISABLE_SSH_CONFIG=1` is set by default to avoid NetBird writing OpenSSH client configuration on OpenWrt systems that normally use dropbear.
- `NB_DNS_STATE_FILE=/var/lib/netbird/state.json` is set by default to avoid unnecessary persistent flash writes.
- The package depends on `kmod-wireguard`, matching the official OpenWrt package dependency model.
- Custom `state_dir` values are created by the init script, but their permissions are left to the operator. The init script only enforces `0700` on the default `/root/.config/netbird` path.
- For additional simple NetBird arguments, prefer OpenWrt-native UCI list values:

```sh
uci add_list netbird.main.extra_arg='--disable-dns'
uci add_list netbird.main.extra_arg='--disable-firewall'
uci commit netbird
/etc/init.d/netbird restart
```

`option extra_args` remains available for simple whitespace-separated legacy flags, but avoid quoted values with spaces there. Use `list extra_arg` for cleaner OpenWrt-native configuration.

A touch inelegant, but occasionally necessary on routers with opinions of their own.
