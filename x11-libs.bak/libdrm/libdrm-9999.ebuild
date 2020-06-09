# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
EGIT_REPO_URI="https://gitlab.freedesktop.org/mesa/drm.git"
CROS_WORKON_PROJECT="chromiumos/third_party/libdrm"
CROS_WORKON_BLACKLIST="1"

inherit xorg-2 cros-workon

DESCRIPTION="X.Org libdrm library"
HOMEPAGE="http://dri.freedesktop.org/"
SRC_URI=""

# This package uses the MIT license inherited from Xorg but fails to provide
# any license file in its source, so we add X as a license, which lists all
# the Xorg copyright holders and allows license generation to pick them up.
LICENSE="|| ( MIT X )"
SLOT="0"
KEYWORDS="~*"
VIDEO_CARDS="amdgpu exynos freedreno intel nouveau omap radeon vc4 vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS} libkms manpages +udev"
REQUIRED_USE="video_cards_exynos? ( libkms )"
RESTRICT="test" # see bug #236845

RDEPEND="dev-libs/libpthread-stubs
	udev? ( virtual/udev )
	video_cards_amdgpu? ( dev-util/cunit )
	video_cards_intel? ( >=x11-libs/libpciaccess-0.10 )
	!<x11-libs/libdrm-tests-2.4.58-r3
"

DEPEND="${RDEPEND}"

XORG_EAUTORECONF=yes

src_prepare() {
	epatch "${FILESDIR}"/Add-Mediatek-proprietary-format.patch
	epatch "${FILESDIR}"/add-DRM_IOCTL_VGEM_MODE_MAP_DUMB-support.patch
	epatch "${FILESDIR}"/Add-header-for-Rockchip-DRM-userspace.patch
	epatch "${FILESDIR}"/Add-header-for-Mediatek-DRM-userspace.patch
	epatch "${FILESDIR}"/Add-Evdi-module-userspace-api-file.patch
	epatch "${FILESDIR}"/Add-Rockchip-AFBC-modifier.patch
	epatch "${FILESDIR}"/Add-back-VENDOR_NV-name.patch

	xorg-2_src_prepare
}

src_configure() {
	XORG_CONFIGURE_OPTIONS=(
		--enable-install-test-programs
		$(use_enable video_cards_amdgpu amdgpu)
		$(use_enable video_cards_exynos exynos-experimental-api)
		$(use_enable video_cards_freedreno freedreno)
		$(use_enable video_cards_intel intel)
		$(use_enable video_cards_nouveau nouveau)
		$(use_enable video_cards_omap omap-experimental-api)
		$(use_enable video_cards_radeon radeon)
		$(use_enable video_cards vc4 vc4)
		$(use_enable video_cards_vmware vmwgfx)
		$(use_enable libkms)
		$(use_enable manpages)
		$(use_enable udev)
		--disable-cairo-tests
	)
	xorg-2_src_configure
}
