cros_post_src_prepare_vmware_patches() {
  if [ ${PV} == "9999" -o "${SKIP_VMWARE_KERNEL_PATCHES}" == "1" ]; then
    return
  fi
  eapply ${VMWARE_BASHRC_FILESDIR}/*.patch
}
