set -o errexit
set -o nounset
set -o pipefail

pushd vendor/k8s.io/client-go 
files=$(find . -name "*.go" \
        \(                         \
            -not \(                    \
                \(                     \
                    -path ./pkg/api\* -o  \
                    -path "./pkg/apis/*" -o \
                    -path "./informer*" -o \
                    -path "./kubernetes*" -o \
                    -path "./listers*" \
                \) -prune              \
            \)                         \
        \))

files=$(grep -l "k8s.io/client-go/pkg/api*" $files)
echo $files

for file in $files; do
    sed -i "s|k8s.io/client-go/pkg/apis|k8s.io/api|g" $file
    sed -i "s|k8s.io/client-go/pkg/api/v1|k8s.io/api/core/v1|g" $file
done
popd

