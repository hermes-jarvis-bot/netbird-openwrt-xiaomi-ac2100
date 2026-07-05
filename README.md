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
| NetBird asset | `netbird_0.74.2_linux_mipsle_softfloat.tar.gz` |
| Asset SHA256 | `09044a1b5811311a386090b5200519f4b6e311d21a97d62b369c00ab4f1f5d3d` |

The package uses the upstream prebuilt `linux/mipsle soft-float` binary, which matches the ramips/mt7621 little-endian MIPS target class used by Xiaomi AC2100 OpenWrt images.

## Files

```text
package/netbird/Makefile              OpenWrt package definition
package/netbird/files/netbird.init    procd init script
package/netbird/files/netbird.config  UCI defaults
scripts/build-sdk.sh                  reproducible SDK build helper
scripts/update-netbird-version.sh     helper to bump to latest NetBird release
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

## Install on router

Copy the generated `.ipk` to the router and install it:

```sh
opkg update
opkg install ./netbird_0.74.2-1_mipsel_24kc.ipk
```

If dependencies are not already present, install them from the matching OpenWrt 24.10 package feed:

```sh
opkg install ca-bundle kmod-tun ip-full iptables-nft
```

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
ip link show wt0
```

## Operational notes

- The service is disabled by default; installation alone will not join the router to a NetBird network.
- The setup key is read from `/etc/netbird/setup.key` by default and should be mode `0600`.
- OpenWrt 24.10 uses firewall4/nftables; this package depends on `iptables-nft` for compatibility with clients expecting iptables-style commands.
- If NetBird should not alter DNS or firewall state, pass advanced flags via UCI `extra_args`, for example:

```sh
uci set netbird.main.extra_args='--disable-dns --disable-firewall'
uci commit netbird
/etc/init.d/netbird restart
```

A touch inelegant, but occasionally necessary on routers with opinions of their own.
