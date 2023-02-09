# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
    sys-devel/arc-build
    sys-devel/arc-llvm
    x11-libs/arc-libdrm
    media-libs/arc-mesa-vmware
    media-libs/arc-cros-gralloc
"

DEPEND="${RDEPEND}"
