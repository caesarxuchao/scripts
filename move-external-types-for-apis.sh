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
storage/v1
admissionregistration/v1alpha1
networking/v1"


filesToMove="types.go
types_swagger_doc_generated.go
types.generated.go
generated.pb.go
zz_generated.deepcopy.go"

filesToCopy="register.go
doc.go"

for gv in $GROUP_VERSIONS; do
    group=${gv%/*}
    echo group is $group
    newFromKubeRoot="vendor/k8s.io/api/${gv}"
    newAbsolute="$K1/$newFromKubeRoot"
    mkdir -p $newAbsolute
    originFromKubeRoot="pkg/apis/${gv}"
    originAbsolute="$K1/$originFromKubeRoot"

    for file in $filesToMove; do
        mv $originAbsolute/$file $newAbsolute/$file || true
    done

    for file in $filesToCopy; do
        cp $originAbsolute/$file $newAbsolute/$file || true
    done

    originDoc="$originAbsolute/doc.go"
    sed -i "/deepcopy-gen/d" "$originDoc"
    sed -i "/openapi-gen/d" "$originDoc"
    sed -i "s|conversion-gen=k8s.io/kubernetes/pkg/apis/$group|\
conversion-gen=k8s.io/kubernetes/pkg/apis/$group\n\
// +k8s:conversion-gen-external-types=../../../../${newFromKubeRoot}|g" "$originDoc"
    sed -i "s|defaulter-gen\(.*\)|\
defaulter-gen\1\n\
// +k8s:defaulter-gen-input=../../../../${newFromKubeRoot}|g" "$originDoc"

    newDoc="$newAbsolute/doc.go"
    sed -i "/conversion-gen/d" "$newDoc"
    sed -i "/defaulter-gen/d" "$newDoc"
    
    newRegisterDoc="$newAbsolute/register.go"
    sed -i "s|addKnownTypes|AddKnownTypes|g" $newRegisterDoc
    sed -i "s|, addDefaultingFuncs||g" $newRegisterDoc
    sed -i "s|, addConversionFuncs||g" $newRegisterDoc
    sed -i "s|, RegisterDefaults||g" $newRegisterDoc

    version=${gv#*/}
    originRegisterDoc="$originAbsolute/register.go"
    sed -i "/TODO/,+2d" $originRegisterDoc
	sed -i "s|&SchemeBuilder|\&$version.SchemeBuilder|g" $originRegisterDoc
    sed -i '/func addKnownTypes/,$d' $originRegisterDoc
    sed -i "/Adds the list of known types to/d" $originRegisterDoc
    sed -i "s|addKnownTypes|$version.AddKnownTypes|g" $originRegisterDoc

    newDeepcopy="$newAbsolute/zz_generated.deepcopy.go"
    sed -i "s|k8s.io/kubernetes/pkg/apis|k8s.io/api|g" $newDeepcopy
done

sed -i "s|k8s.io/kubernetes/pkg/apis/batch/v1|k8s.io/api/batch/v1|g" $K1/vendor/k8s.io/api/batch/v2alpha1/types.go
sed -i "s|k8s.io/kubernetes/pkg/apis/batch/v1|k8s.io/api/batch/v1|g" $K1/vendor/k8s.io/api/batch/v2alpha1/types.generated.go

# TODO: manually fix these two files?
rm $K1/vendor/k8s.io/api/rbac/v1alpha1/generated.pb.go
rm $K1/vendor/k8s.io/api/rbac/v1beta1/generated.pb.go
