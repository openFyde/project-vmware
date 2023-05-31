# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/mesa/mesa-7.9.ebuild,v 1.3 2010/12/05 17:19:14 arfrever Exp $

EAPI="7"

CROS_WORKON_COMMIT="484ba115709176ba761f70f652eaee387e9ae7d8"
CROS_WORKON_TREE="7a0e39b057036b451cac9f794b6572f9b6f26798"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_LOCALNAME="mesa-reven"
CROS_WORKON_EGIT_BRANCH="chromeos-reven"

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/mesa"

inherit meson multilib-minimal flag-o-matic toolchain-funcs cros-workon arc-build cros-sanitizers

DESCRIPTION="OpenGL-like graphic library for Linux"
HOMEPAGE="http://mesa3d.sourceforge.net/"

# Most of the code is MIT/X11.
# ralloc is LGPL-3
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT LGPL-3 SGI-B-2.0"
SLOT="0"
KEYWORDS="*"

INTEL_CARDS="intel"
RADEON_CARDS="amdgpu radeon"
VIDEO_CARDS="${INTEL_CARDS} ${RADEON_CARDS} llvmpipe mach64 mga nouveau powervr
	r128 savage sis vmware tdfx via freedreno virgl mediatek msm"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	android_aep -android_gles2 -android_gles30
	+android_gles31 -android_gles32 -android_vulkan_compute_0 -angle -swvulkan
	+cheets classic debug dri +egl +gallium
	-gbm +gles1 +gles2 -llvm +nptl pic selinux +shared-glapi -vulkan -X xlib-glx
	cheets_user cheets_user_64 arcpp arcvm vmware_mks"

# llvmpipe requires ARC++ _userdebug images, ARC++ _user images can't use it
# (b/33072485, b/28802929).
# Only allow one vulkan driver as they all write vulkan.cheets.so.
REQUIRED_USE="
	^^ ( android_gles2 android_gles30 android_gles31 android_gles32 )
	android_aep? ( !android_gles2 !android_gles30 )
	angle? ( vulkan !egl )
	android_vulkan_compute_0? ( vulkan )"

DEPEND="cheets? (
		>=x11-libs/arc-libdrm-2.4.82[${MULTILIB_USEDEP}]
		llvm? ( sys-devel/arc-llvm:=[${MULTILIB_USEDEP}] )
	)"

RDEPEND="${DEPEND}"

# It is slow without texrels, if someone wants slow
# mesa without texrels +pic use is worth the shot
QA_EXECSTACK="usr/lib*/opengl/xorg-x11/lib/libGL.so*"
QA_WX_LOAD="usr/lib*/opengl/xorg-x11/lib/libGL.so*"

# Fix lint errors
: "${ARC_PREFIX:=}"
: "${ARC_SYSROOT:=}"

# Think about: ggi, fbcon, no-X configs

pkg_setup() {
	# workaround toc-issue wrt #386545
	use ppc64 && append-flags -mminimal-toc
	# workaround for b/226576333. Also, lld is faster then gold
	append-flags -fuse-ld=lld

	# Remove symlinks created by an earlier version so we don't have
	# install conflicts.
	# TODO: Delete this after June 2019, since everybody should have
	# upgraded by then.
	local d
	for d in EGL GL GLES GLES2 GLES3 KHR; do
		local replaced_link="${ROOT}${ARC_PREFIX}/vendor/include/${d}"
		if [[ -L "${replaced_link}" ]]; then
			rm -f "${replaced_link}"
		fi
	done
}

src_prepare() {
	# workaround for cros-workon not preserving git metadata
	if [[ ${PV} == 9999* && "${CROS_WORKON_INPLACE}" != "1" ]]; then
		echo "#define MESA_GIT_SHA1 \"git-deadbeef\"" > src/git_sha1.h
	fi

	# apply patches
	if [[ ${PV} != 9999* && -n ${SRC_PATCHES} ]]; then
		EPATCH_FORCE="yes" \
		EPATCH_SOURCE="${WORKDIR}/patches" \
		EPATCH_SUFFIX="patch" \
		epatch
	fi
	# FreeBSD 6.* doesn't have posix_memalign().
	if [[ ${CHOST} == *-freebsd6.* ]]; then
		sed -i \
			-e "s/-DHAVE_POSIX_MEMALIGN//" \
			configure.ac || die
	fi

	# Restrict gles version based on USE flag. (See crbug.com/30202361, b/30202371, b/31041422, b:68023287)
	if use android_gles32; then
		einfo "Limiting android to gles32."
		eapply "${FILESDIR}/gles32/0001-limit-gles-version.patch"
	elif use android_gles31; then
		einfo "Limiting android to gles31."
		eapply "${FILESDIR}/gles31/0001-limit-gles-version.patch"
	elif use android_gles30; then
		einfo "Limiting android to gles30."
		eapply "${FILESDIR}/gles30/0001-limit-gles-version.patch"
	elif use android_gles2; then
		einfo "Limiting android to gles2."
		eapply "${FILESDIR}/gles2/0001-limit-gles-version.patch"
	fi

  eapply ${FILESDIR}/patches/angle_draw.patch
  eapply ${FILESDIR}/patches/svga_format_v20.patch

	default
}

src_configure() {
	sanitizers-setup-env
	cros_optimize_package_for_speed

	if use cheets; then
		#
		# cheets-specific overrides
		#

		arc-build-select-clang
	fi

	multilib-minimal_src_configure
}

multilib_src_configure() {
	tc-getPROG PKG_CONFIG pkg-config

	if use !gallium && use !classic && use !vulkan; then
		ewarn "You enabled neither classic, gallium, nor vulkan "
		ewarn "USE flags. No hardware drivers will be built."
	fi

	if use egl; then
		GALLIUM_DRIVERS=svga
	fi

	if use vulkan; then
		VULKAN_DRIVERS=""
	fi

	export LLVM_CONFIG=${SYSROOT}/usr/bin/llvm-config-host
	EGL_PLATFORM="surfaceless"

	if use cheets; then
		#
		# cheets-specific overrides
		#

		# Use llvm-config coming from ARC++ build.
		export LLVM_CONFIG="${ARC_SYSROOT}/build/bin/llvm-config-host"

		# FIXME(tfiga): Possibly use flag?
		EGL_PLATFORM="android"

		# The AOSP build system defines the Make variable
		# PLATFORM_SDK_VERSION, and Mesa's Android.mk files use it to
		# define the macro ANDROID_API_LEVEL. Arc emulates that here.
		if [[ -n "${ARC_PLATFORM_SDK_VERSION}" ]]; then
			CPPFLAGS+=" -DANDROID_API_LEVEL=${ARC_PLATFORM_SDK_VERSION}"
		fi

		#
		# end of arc-mesa specific overrides
		#
	fi

	if ! use llvm; then
		export LLVM_CONFIG="no"
	fi

	arc-build-create-cross-file

	emesonargs+=(
		--prefix="${ARC_PREFIX}/vendor"
		--sysconfdir=/system/vendor/etc
		-Ddri-search-path="/system/$(get_libdir)/dri:/system/vendor/$(get_libdir)/dri"
		-Dgallium-va=disabled
		-Dgallium-vdpau=disabled
		-Dgallium-omx=disabled
		-Dglx=disabled
		-Ddri3=disabled
		-Dgles-lib-suffix=_mesa
		-Degl-lib-suffix=_mesa
		-Dplatforms="${EGL_PLATFORM}"
		$(meson_use llvm)
		$(meson_use egl)
		$(meson_use gbm)
		$(meson_use gles1)
		$(meson_use gles2)
		$(meson_use selinux)
		$(meson_use shared-glapi)
		-Ddri-drivers=
		-Dgallium-drivers="${GALLIUM_DRIVERS}"
		-Dvulkan-drivers="${VULKAN_DRIVERS}"
    -Dvmware-mks-stats=$(usex vmware_mks true false)
		--buildtype $(usex debug debug release)
		--cross-file="${ARC_CROSS_FILE}"
		-Dplatform-sdk-version="${ARC_PLATFORM_SDK_VERSION}"
	)

	meson_src_configure
}

# The meson eclass exports src_compile but not multilib_src_compile. src_compile
# gets overridden by multilib-minimal
multilib_src_compile() {
	meson_src_compile
}

multilib_src_install() {
	if use vulkan; then
		exeinto "${ARC_PREFIX}/vendor/$(get_libdir)/hw"
		newexe "${BUILD_DIR}"/src/virtio/vulkan/libvulkan_virtio.so vulkan.cheets.so
	fi

	# Install symlink for angle GLESv2 lib
	if use angle; then
		dosym egl/libGLESv2_angle.so "${ARC_PREFIX}/vendor/$(get_libdir)/libGLESv2_angle.so"
	fi

	if ! use egl; then
		return
	fi

	exeinto "${ARC_PREFIX}/vendor/$(get_libdir)"
	newexe "${BUILD_DIR}/src/mapi/shared-glapi/libglapi.so.0" libglapi.so.0

	exeinto "${ARC_PREFIX}/vendor/$(get_libdir)/egl"
	newexe "${BUILD_DIR}/src/egl/libEGL_mesa.so" libEGL_mesa.so
	newexe "${BUILD_DIR}/src/mapi/es1api/libGLESv1_CM_mesa.so" libGLESv1_CM_mesa.so
	newexe "${BUILD_DIR}/src/mapi/es2api/libGLESv2_mesa.so" libGLESv2_mesa.so

	exeinto "${ARC_PREFIX}/vendor/$(get_libdir)/dri"
	newexe "${BUILD_DIR}/src/gallium/targets/dri/libgallium_dri.so" vmwgfx_dri.so
}

multilib_src_install_all() {
	# For documentation on the feature set represented by each XML file
	# installed into /vendor/etc/permissions, see
	# <https://developer.android.com/reference/android/content/pm/PackageManager.html>.
	# For example XML files for each feature, see
	# <https://android.googlesource.com/platform/frameworks/native/+/master/data/etc>.

	# Install init files to advertise supported API versions.
	insinto "${ARC_PREFIX}/vendor/etc/init"
	if use angle; then
		einfo "Using angle."
		doins "${FILESDIR}/angle/init.gpu.rc"
	elif use egl; then
		if use android_gles32; then
			doins "${FILESDIR}/gles32/init.gpu.rc"
		elif use android_gles31; then
			doins "${FILESDIR}/gles31/init.gpu.rc"
		elif use android_gles30; then
			doins "${FILESDIR}/gles30/init.gpu.rc"
		elif use android_gles2; then
			doins "${FILESDIR}/gles2/init.gpu.rc"
		fi
	fi

	# Install vulkan related files.
	if use vulkan; then
		einfo "Using android vulkan."
		insinto "${ARC_PREFIX}/vendor/etc/init"
		doins "${FILESDIR}/vulkan.rc"

		insinto "${ARC_PREFIX}/vendor/etc/permissions"
		doins "${FILESDIR}/android.hardware.vulkan.version-1_1.xml"
		if use video_cards_intel || use video_cards_mediatek || use video_cards_msm; then
			doins "${FILESDIR}/android.hardware.vulkan.level-1.xml"
		else
			doins "${FILESDIR}/android.hardware.vulkan.level-0.xml"
		fi
	elif use swvulkan; then
		einfo "Using swiftshader vulkan."
		insinto "${ARC_PREFIX}/vendor/etc/init"
		doins "${FILESDIR}/sw.vulkan.rc"
	fi

	if use android_vulkan_compute_0; then
		einfo "Using android vulkan_compute_0."
		insinto "${ARC_PREFIX}/vendor/etc/permissions"
		doins "${FILESDIR}/android.hardware.vulkan.compute-0.xml"
	fi

	# Install permission file to declare opengles aep support.
	if use android_aep; then
		einfo "Using android aep."
		insinto "${ARC_PREFIX}/vendor/etc/permissions"
		doins "${FILESDIR}/android.hardware.opengles.aep.xml"
	fi

	# Install the dri header for arc-cros-gralloc
	if use egl; then
		insinto "${ARC_PREFIX}/vendor/include/GL"
		doins -r "${S}/include/GL/internal"
	fi
}
