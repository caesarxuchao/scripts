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

files=$(find pkg/ cmd/ cluster/ plugin/ federation/ test/ -name "*.go" \
        \(                         \
            -not \(                    \
                \(                     \
                    -path pkg/api\* -o  \
                    -path "pkg/apis/*" -o \
                    -path vendor/k8s.io/client-go\*   \
                \) -prune              \
            \)                         \
        \))

files=$(grep -l "k8s.io/kubernetes/pkg/apis.*v" $files)

readonly files 

#============= section II, fix the original packages======================"
for gv in $GROUP_VERSIONS; do
    # git doesn't understand symlink, so use staging/src
    new_import_path="\"k8s.io/api/${gv}\""
    old_import_path="\"k8s.io/kubernetes/pkg/apis/${gv}\""
    echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"
done


#certificates
# certificates/v1beta1
certificates_exceptions="ParseCSR
"
for word in $certificates_exceptions; do
    new_import_path="\"k8s.io/api/certificates/v1beta1\""
    old_import_path="k8s_certificates_v1beta1 \"k8s.io/kubernetes/pkg/apis/certificates/v1beta1\""
    subfiles=$(grep -l "[_a-z0-9]*$word" $files)
    subfiles=$(grep -l $new_import_path $subfiles)
    sed -i -r "s/[_a-z0-9]*\.$word/k8s_certificates_v1beta1.$word/g" $subfiles
    sed -i -r "s|$new_import_path|$new_import_path\n$old_import_path|g" $subfiles
    goimports -w $subfiles
done
