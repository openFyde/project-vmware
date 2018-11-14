# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"
CROS_WORKON_PROJECT="chromiumos/third_party/libdrm"
CROS_WORKON_LOCALNAME="libdrm"

P=${P#"arc-"}
PN=${PN#"arc-"}
S="${WORKDIR}/${P}"

XORG_MULTILIB=yes
inherit xorg-2 cros-workon arc-build

DESCRIPTION="X.Org libdrm library"
HOMEPAGE="http://dri.freedesktop.org/"
SRC_URI=""

# This package uses the MIT license inherited from Xorg but fails to provide
# any license file in its source, so we add X as a license, which lists all
# the Xorg copyright holders and allows license generation to pick them up.
LICENSE="|| ( MIT X )"
SLOT="0"
KEYWORDS="~*"
VIDEO_CARDS="amdgpu exynos freedreno nouveau omap radeon vc4 vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS} libkms manpages +udev"
RESTRICT="test" # see bug #236845

RDEPEND=""
DEPEND="${RDEPEND}"

XORG_EAUTORECONF=yes

src_prepare() {
	xorg-2_src_prepare
}

src_configure() {
	# FIXME(tfiga): Could inherit arc-build invoke this implicitly?
	arc-build-select-clang

	XORG_CONFIGURE_OPTIONS=(
		--disable-install-test-programs
		$(use_enable video_cards_amdgpu amdgpu)
		$(use_enable video_cards_exynos exynos-experimental-api)
		$(use_enable video_cards_freedreno freedreno)
		$(use_enable video_cards_nouveau nouveau)
		$(use_enable video_cards_omap omap-experimental-api)
		$(use_enable video_cards_radeon radeon)
		$(use_enable video_cards_vc4 vc4)
		$(use_enable video_cards_vmware vmwgfx)
		$(use_enable libkms)
		$(use_enable manpages)
		$(use_enable udev)
		--disable-cairo-tests
		--disable-intel
		"--prefix=${ARC_PREFIX}/vendor"
		"--datadir=${ARC_PREFIX}/vendor/usr/share"
	)
	xorg-2_src_configure
}
