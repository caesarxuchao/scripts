set -o errexit
set -o nounset
set -o pipefail

files=$(find pkg/ cmd/ cluster/ plugin/ federation/ test/ staging/ -name "*.go" \
        \(                         \
            -not \(                    \
                \(                     \
                    -path pkg/api\* -o  \
                    -path "pkg/apis/*" -o \
                    -path staging/src/k8s.io/client-go\* -o \
                    -path vendor/k8s.io/client-go\*   \
                \) -prune              \
            \)                         \
        \))

files=$(grep -l "k8s.io/client-go/pkg/api" $files)
new_import_path="\"k8s.io/api/core/v1\""
old_import_path="\"k8s.io/client-go/pkg/api/v1\""
echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"

new_import_path="\"k8s.io/api"
old_import_path="\"k8s.io/client-go/pkg/apis"
echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"

# these are pkg/api/v1 subfolders, should be able to use the utility function in kubernetes now. Of course the files could be in staging.
files=$(IFS=" "; echo $files | grep -v staging)
new_import_path="\"k8s.io/kubernetes/pkg/api/v1"
old_import_path="\"k8s.io/client-go/pkg/api/v1"
echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"

# exceptions
file="cmd/kubeadm/app/phases/apiconfig/clusterroles.go"
old="rbac \"k8s.io/api/rbac/v1beta1\""
new="rbachelper \"k8s.io/kubernetes/pkg/apis/rbac/v1beta1\""
sed -i "s|$old|$old\n$new|g" $file
sed -i "s|rbac.NewRule|rbachelper.NewRule|g" $file

