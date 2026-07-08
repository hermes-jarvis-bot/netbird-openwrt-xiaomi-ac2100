# NetBird for OpenWrt 24.10 — Xiaomi AC2100

This project packages the upstream NetBird peer client for OpenWrt 24.10 on the Xiaomi AC2100 family.

## Target

| Item | Value |
| --- | --- |
| OpenWrt release | `24.10.0` |
| Target/subtarget | `ramips/mt7621` |
| Default profile | `xiaomi_mi-router-ac2100` |
| Also relevant profile | `xiaomi_redmi-router-ac2100` |
| OpenWrt package arch | `mipsel_24kc` |
| NetBird release | `v0.74.2` |
| OpenWrt package release | `r3` |
| OpenWrt package version | `0.74.2-r3` |
| NetBird asset | `netbird_0.74.2_linux_mipsle_softfloat.tar.gz` |
| Asset SHA256 | `09044a1b5811311a386090b5200519f4b6e311d21a97d62b369c00ab4f1f5d3d` |

The package uses the upstream prebuilt `linux/mipsle soft-float` binary, which matches the ramips/mt7621 little-endian MIPS target class used by Xiaomi AC2100 OpenWrt images.

The service layout deliberately follows the official OpenWrt `netbird` package where it matters for recent profile-based NetBird releases: persistent profile state under `/root/.config/netbird`, SSH config writes disabled on OpenWrt/dropbear systems, and DNS state kept under `/var/lib/netbird` to reduce flash wear.

## Why not the official OpenWrt package?

OpenWrt 24.10 currently carries an older NetBird package in the official feeds. Recent NetBird releases require a newer Go toolchain than the OpenWrt 24.10 SDK provides for source builds, so this project packages the upstream prebuilt `linux/mipsle soft-float` binary while keeping OpenWrt-style service defaults.

## Files

```text
package/netbird/Makefile              OpenWrt package definition
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

From the project root:

```sh
./scripts/build-sdk.sh
```

By default this downloads and uses:

```text
https://downloads.openwrt.org/releases/24.10.0/targets/ramips/mt7621/openwrt-sdk-24.10.0-ramips-mt7621_gcc-13.3.0_musl.Linux-x86_64.tar.zst
```

The output `.ipk` will be under the SDK `bin/packages/...` directory printed by the script.

To target Redmi AC2100 profile metadata validation instead:

```sh
PROFILE=xiaomi_redmi-router-ac2100 ./scripts/build-sdk.sh
```

The package itself is architecture-specific rather than image-profile-specific, but the profile check prevents accidentally building against the wrong OpenWrt target.

For SDK archives with a different toolchain suffix, override the SDK basename explicitly:

```sh
SDK_BASENAME=openwrt-sdk-24.10.0-ramips-mt7621_gcc-13.3.0_musl.Linux-x86_64 ./scripts/build-sdk.sh
```

## Download prebuilt packages

Prebuilt `.ipk` artifacts are published under GitHub Releases:

https://github.com/hermes-jarvis-bot/netbird-openwrt-xiaomi-ac2100/releases

For the current package release:

```sh
wget https://github.com/hermes-jarvis-bot/netbird-openwrt-xiaomi-ac2100/releases/download/netbird-0.74.2-r3-openwrt-24.10.0/netbird_0.74.2-r3_mipsel_24kc.ipk
wget https://github.com/hermes-jarvis-bot/netbird-openwrt-xiaomi-ac2100/releases/download/netbird-0.74.2-r3-openwrt-24.10.0/SHA256SUMS
sha256sum -c SHA256SUMS
```

## Install on router

Copy the generated or downloaded `.ipk` to the router and install it:

```sh
opkg update
opkg install ca-bundle kmod-wireguard
opkg install ./netbird_0.74.2-r3_mipsel_24kc.ipk
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
