set -o errexit
set -o nounset
set -o pipefail

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
storage/v1
admissionregistration/v1alpha1
networking/v1"

for gv in $GROUP_VERSIONS; do
    rm $K1/pkg/apis/$gv/generated.proto
done

rm $K1/pkg/api/v1/generated.proto
