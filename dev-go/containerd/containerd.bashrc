cros_pre_src_prepare_vmware_patch() {
  CROS_GO_PACKAGES+=(
    "github.com/containerd/containerd/api/types"
    "github.com/containerd/containerd/api/services/containers/v1"
    "github.com/containerd/containerd/api/services/tasks/v1"
    "github.com/containerd/containerd/api/types/task"
  )
}
