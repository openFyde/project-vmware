cros_post_src_prepare_vmwre_patch() {
  eapply ${VMWARE_BASHRC_FILESDIR}/001-fix-go-path.patch
  eapply ${VMWARE_BASHRC_FILESDIR}/002-pass-go-files-test.patch
}

cros_pre_src_configure_vmware_patch() {
  export CUSTOM_PAM_CPPFLAGS="-I${ROOT}/usr/include"
  export CUSTOM_GRPC_CPPFLAGS="-I${ROOT}/usr/include"
  export CUSTOM_CURL_CPPFLAG="-I${ROOT}/usr/include"
  export CUSTOM_CURL_CPPFLAGS="-I${ROOT}/usr/include"
  export CUSTOM_PROTOBUF_CPPFLAGS="-I${ROOT}/usr/include"
  export CUSTOM_GOPATH="${ROOT}/usr/lib/gopath/src"
}

cros_post_src_install_vmware_patch() {
  insinto /etc/init
  if use vgauth; then
    doins ${VMWARE_BASHRC_FILESDIR}/vm-vgauth.conf
    newins ${VMWARE_BASHRC_FILESDIR}/vgauth-open-vm-tools.conf open-vm-tools.conf
  else
    doins ${VMWARE_BASHRC_FILESDIR}/open-vm-tools.conf
  fi
  doins ${VMWARE_BASHRC_FILESDIR}/mount-vmware-share.conf
}
