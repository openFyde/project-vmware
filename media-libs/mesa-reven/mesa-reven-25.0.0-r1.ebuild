# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="64552db2f8358f5e7b3f0326d8ac261823dfa5d0"
CROS_WORKON_TREE="4405aacb3e607c0900d16b36f7a2ad95ebc049d9"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_LOCALNAME="mesa"
CROS_WORKON_EGIT_BRANCH="upstream/25.0"

KEYWORDS="*"

PYTHON_COMPAT=( python3_{8..11} )
inherit meson flag-o-matic cros-workon cros-sanitizers python-any-r1

DESCRIPTION="The Mesa 3D Graphics Library"
HOMEPAGE="http://mesa3d.org/"

# Most of the code is MIT/X11.
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT SGI-B-2.0"

IUSE="borealis_host debug libglvnd perfetto tools vulkan zstd"

COMMON_DEPEND="
	dev-libs/expat
	libglvnd? ( media-libs/libglvnd )
	>=sys-libs/zlib-1.2.8
	>=x11-libs/libdrm-2.4.110
	virtual/libudev:=
"

RDEPEND="${COMMON_DEPEND}
	!libglvnd? ( !media-libs/libglvnd )
	!media-libs/mesa
	zstd? ( app-arch/zstd )
"

DEPEND="${COMMON_DEPEND}
	perfetto? ( >=chromeos-base/perfetto-29.0 )
"

BDEPEND="
	dev-util/glslang
	dev-util/intel_clc
	dev-util/spirv-llvm
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	$(python_gen_any_dep '
		dev-python/mako[${PYTHON_USEDEP}]
		dev-python/ply[${PYTHON_USEDEP}]
	')
"

python_check_deps() {
	python_has_version -b \
		"dev-python/mako[${PYTHON_USEDEP}]" \
		"dev-python/ply[${PYTHON_USEDEP}]"
}

pkg_setup() {
	python-any-r1_pkg_setup
	cros-workon_pkg_setup
}

setup_performance_flags() {
	# Tidying up build command line by removing
	# previous O? flags, not a functional change.
	filter-flags '-O?'

	# Use O3 instead of O2/Os flags, O3 turns on
	# additional optimization flags over O2
	# which are inclined towards performance
	append-cppflags -O3
}

src_configure() {
	sanitizers-setup-env
	cros_optimize_package_for_speed
	# overriding platform default flags since we
	# observe performance gains. see b/294626084
	setup_performance_flags

	if use borealis_host; then
		tools=drm-shim
	else
		tools=''
	fi

	emesonargs+=(
		-Dllvm=disabled
		-Ddri3=disabled
		-Dshader-cache-default=false
		-Dglx=disabled
		-Degl=enabled
		-Dgbm=disabled
		-Dgles1=disabled
		-Dgles2=enabled
		-Dshared-glapi=enabled
		-Dgallium-drivers=svga
		-Dgallium-vdpau=disabled
		-Dgallium-xa=disabled
		-Dglvnd=$(usex libglvnd true false)
		-Dperfetto=$(usex perfetto true false)
#		-Dintel-clc=system
		$(meson_feature zstd)
		# Set platforms empty to avoid the default "auto" setting. If
		# platforms is empty meson.build will add surfaceless.
		-Dplatforms=''
		-Dtools="${tools}"
		--buildtype $(usex debug debug release)
		-Dvulkan-drivers=''
	)

	meson_src_configure
}

# Sometimes images need only specific tools, not all those built. Return the
# list of unneeded ones for cleanup later to avoid growing the release image
# especially on legacy 2GB configs.
get_tools_to_cleanup() {
	# If user requested in the chroot, skip cleanup.
	! use tools || return

	# If >=4GB devices, skip cleanup.
	! use borealis_host || return

	# Tools to retain on the image.
	# * aubinator_error_decode is needed for decoding the i915_error_state on
	#   device, which gives critical information for debugging GPU hangs.
	#   We run this during Chrome crash reporting.
	required_tools=("aubinator_error_decode")

	# Ignore required_tools in ls of tools directory and return.
	cd "${BUILD_DIR}"/src/intel/tools || die
	local lsargs
	for tool in "${required_tools[@]}"; do
		lsargs+=("-I" "${tool}")
	done
	ls "${lsargs[@]}"
}

src_install() {

	meson_src_install

	rm -v -rf "${ED}/usr/include"
}

PATCHES=(
  ${FILESDIR}/angle_draw.patch
  ${FILESDIR}/svga_format_v20.patch
)
