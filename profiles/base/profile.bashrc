vmware_stack_bashrc() {
  local cfg cfgd

  cfgd="/mnt/host/source/src/overlays/project-vmware/${CATEGORY}/${PN}"
  for cfg in ${PN} ${P} ${PF} ; do
    cfg="${cfgd}/${cfg}.bashrc"
    [[ -f ${cfg} ]] && . "${cfg}"
  done

  export VMWARE_BASHRC_FILESDIR="${cfgd}/files"
}

vmware_stack_bashrc
