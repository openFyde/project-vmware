cros_pre_src_prepare_vmware_patch() {
  CROS_GO_PACKAGES+=(
    "github.com/gogo/protobuf/types"
    "github.com/gogo/protobuf/sortkeys"
  )
}

#    "github.com/gogo/protobuf/gogoproto"
#    "github.com/gogo/protobuf/protoc-gen-gogo/descriptor"
