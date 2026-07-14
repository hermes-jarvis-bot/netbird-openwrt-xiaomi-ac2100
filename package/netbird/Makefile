include $(TOPDIR)/rules.mk

PKG_NAME:=netbird
PKG_VERSION:=0.74.5
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)_$(PKG_VERSION)_linux_mipsle_softfloat.tar.gz
PKG_SOURCE_URL:=https://github.com/netbirdio/netbird/releases/download/v$(PKG_VERSION)
PKG_HASH:=7d2072c960135d842d4e628cdc977e848747645a7342210ff58ee4623ea83d72
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Ruslan Fomin

include $(INCLUDE_DIR)/package.mk

define Package/netbird
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=NetBird mesh VPN peer client
  URL:=https://netbird.io/
  DEPENDS:=+ca-bundle +kmod-wireguard
endef

define Package/netbird/description
 NetBird peer client packaged for OpenWrt 24.10 ramips/mt7621 devices,
 including Xiaomi Mi Router AC2100 and Redmi Router AC2100.
 This package installs the upstream prebuilt linux/mipsle soft-float binary.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/netbird/conffiles
/etc/config/netbird
endef

define Package/netbird/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/netbird $(1)/usr/bin/netbird
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/netbird.init $(1)/etc/init.d/netbird
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/netbird.config $(1)/etc/config/netbird
	$(INSTALL_DIR) $(1)/etc/netbird
endef

$(eval $(call BuildPackage,netbird))
