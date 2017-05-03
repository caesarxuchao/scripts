set -o errexit
set -o nounset
set -o pipefail

# copied from hack/lib/init.sh
# list of all available group versions.  This should be used when generated code
# or when starting an API server that you want to have everything.
# most preferred version for a group should appear first
GROUP_VERSIONS="\
apps/v1beta1 \
authentication.k8s.io/v1 \
authentication.k8s.io/v1beta1 \
authorization.k8s.io/v1 \
authorization.k8s.io/v1beta1 \
autoscaling/v1 \
autoscaling/v2alpha1 \
batch/v1 \
batch/v2alpha1 \
certificates.k8s.io/v1beta1 \
extensions/v1beta1 \
imagepolicy.k8s.io/v1alpha1 \
policy/v1beta1 \
rbac.authorization.k8s.io/v1beta1 \
rbac.authorization.k8s.io/v1alpha1 \
settings.k8s.io/v1alpha1 \
storage.k8s.io/v1beta1 \
storage.k8s.io/v1"

GROUP_VERSIONS="extensions/v1beta1"

echo $GROUP_VERSIONS


filesToMove="types.go
types_swagger_doc_generated.go
types.generated.go
generated.pb.go"

filesToCopy="register.go
doc.go"

pushd $K1

for gv in "${GROUP_VERSIONS[@]}"; do
    newFromKubeRoot="vendor/k8s.io/api/${gv}"
    mkdir -p $newFromKubeRoot
    originFromKubeRoot="pkg/apis/${gv}"

    for file in $filesToMove; do
        mv $originFromKubeRoot/$file $newFromKubeRoot/$file
    done

    for file in $filesToCopy; do
        mv $originFromKubeRoot/$file $newFromKubeRoot/$file
    done

    originDoc="$originFromKubeRoot/doc.go"
    sed -i "/deepcopy-gen/d" "$originDoc"
    sed -i "/openapi-gen/d" "$originDoc"
    sed -i "s|conversion-gen\(.*\)|conversion-gen\1,external_types=../../../${newFromKubeRoot}|g"  "$originDoc"
    sed -i "s|defaulter-gen\(.*\)|\
        defaulter-gen\1\
        // +k8s:defaulter-gen-input=../../../${newFromKubeRoot}|g" "$originDoc"

    newDoc="$newFromKubeRoot/doc.go"
    sed -i "/conversion-gen/d" "$originDoc"
    sed -i "/defaulter-gen/d" "$originDoc"
done
