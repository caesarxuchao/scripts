set -o errexit
set -o nounset
set -o pipefail

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

files=$(grep -l "k8s.io/client-go/pkg/api" $files)

new_import_path="\"k8s.io/api/core/v1\""
old_import_path="\"k8s.io/client-go/pkg/api/v1\""
echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"

new_import_path="\"k8s.io/api"
old_import_path="\"k8s.io/client-go/pkg/apis"
echo $files | xargs sed -i "s|$old_import_path|$new_import_path|g"
