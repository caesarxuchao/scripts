set -o errexit
set -o nounset
set -o pipefail

# copied from hack/lib/init.sh
GROUP_VERSIONS="apps/v1beta1
authentication/v1
authentication/v1beta1
authorization/v1
authorization/v1beta1
autoscaling/v1
autoscaling/v2alpha1
batch/v1
batch/v2alpha1
certificates/v1beta1
extensions/v1beta1
imagepolicy/v1alpha1
policy/v1beta1
rbac/v1beta1
rbac/v1alpha1
settings/v1alpha1
storage/v1beta1
storage/v1"

files=$(find pkg/ cmd/ cluster/ plugin/ federation/ -name "*.go" \
        \(                         \
            -not \(                    \
                \(                     \
                    -path ./pkg/api -o  \
                    -path ./pkg/apis   \
                    -path ./vendor/k8s.io/client-go   \
                \) -prune              \
            \)                         \
        \))


#============= section II, fix the original packages======================"
for gv in $GROUP_VERSIONS; do
    # git doesn't understand symlink, so use staging/src
    new_import_path="k8s.io/api/${gv}"
    old_import_path="kubernetes/pkg/apis/${gv}"
    echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"
done
