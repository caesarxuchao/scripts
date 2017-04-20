set -o errexit
set -o nounset
set -o pipefail

old_import_path="\"k8s.io/kubernetes/pkg/api/v1\""
new_import_path="\"k8s.io/api/core/v1\""
    
function findfiles() {
find pkg/ cmd/ cluster/ plugin/ federation/ test/ -name "*.go" \
        \(                         \
            -not \(                    \
                \(                     \
                    -name doc.go -o  \
                    -name xxxxxxxconversion.go -o  \
                    -name xxxxxxzz_generated* \
                \) -prune              \
            \)                         \
        \)                         
}

files=$(findfiles)

echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"

old_import_path="\"k8s.io/kubernetes/pkg/api/v1/validation\""
new_import_path="\"k8s.io/api/core/v1/validation\""
echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"

# Convert_v1_PodTemplateSpec_To_api_PodTemplateSpec and DeepCopies is still in v1
# A lot of SetDefaults are still in v1
files=$(find pkg/ cmd/ cluster/ plugin/ federation/ -name "conversion.go" -o -name "zz_generated.conversion.go" -o -name "zz_generated.deepcopy.go")
extra_files="pkg/api/validation/validation.go
pkg/client/clientset_generated/internalclientset/typed/core/internalversion/event_expansion.go
pkg/kubelet/config/common.go
pkg/kubelet/config/config.go
pkg/controller/serviceaccount/tokengetter.go
pkg/registry/core/node/storage/storage.go
pkg/quota/evaluator/core/persistent_volume_claims.go
pkg/quota/evaluator/core/pods.go
pkg/quota/evaluator/core/services.go
plugin/pkg/admission/podtolerationrestriction/admission.go
pkg/kubectl/history.go
pkg/kubectl/rollback.go
pkg/kubectl/rolling_updater.go
pkg/controller/resourcequota/resource_quota_controller.go
pkg/kubelet/kubelet_node_status.go
pkg/kubectl/cmd/util/factory.go"

files="$files $extra_files"

old_import_path="\"k8s.io/api/core/v1\""
new_import_path="k8s_api_v1 \"k8s.io/kubernetes/pkg/api/v1\""
for file in $files; do
    sed -i -r "s|$old_import_path|$old_import_path\n$new_import_path|g" $file
    sed -i -r "s/([[:space:]])(api_v1|v1)\.Convert_v1/\1k8s_api_v1.Convert_v1/g" $file
    sed -i -r "s/([[:space:]])(api_v1|v1)\.Convert_api/\1k8s_api_v1.Convert_api/g" $file
    sed -i -r "s/([[:space:]])(api_v1|v1)\.DeepCopy_v1/\1k8s_api_v1.DeepCopy_v1/g" $file
    goimports -w $file
done

find pkg/apis/batch/v2alpha1 -name *.go | xargs sed -i "s/batch_k8s_api_v1/batch_v1/g" 

#sed -i -r "s|[[:alnum:]_]+\.Convert_v1|k8s_api_v1.Convert_v1|g" $file

git checkout HEAD federation/apis/core/v1/conversion.go
git checkout HEAD federation/client/clientset_generated/federation_clientset/scheme/register.go
git checkout HEAD pkg/client/clientset_generated/clientset/scheme/register.go
git checkout HEAD pkg/api/install/install.go
