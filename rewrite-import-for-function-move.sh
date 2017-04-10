set -o errexit
set -o nounset
set -o pipefail

old_pkg="api"
new_pkg="ref"

old_import_path="\"k8s.io/kubernetes/pkg/api\""
new_import_path="\"k8s.io/kubernetes/pkg/api/$new_pkg\""

new_file="pkg/api/ref/ref.go"

functions="GetPartialReference
GetReference
ErrNilObject
ErrNoSelfLink"

for function in $functions; do
    echo "====================================="
    echo "processing $function"
    files=$(git grep -l $function -- '*.go')
    for file in $files; do
        if [ $file = $new_file ]; then
            continue
        fi
        echo "processing $file"
        sed -i "s/$old_pkg\.$function/$new_pkg.$function/g" $file
        if ! git grep -q "$new_pkg\.$function" $file; then
            echo "no real sed"
            continue
        fi
        if git grep -q "$new_import_path" $file; then
            echo "already update the import path"
            continue
        fi
        sed -i "s|$old_import_path|$old_import_path\n$new_import_path|g" $file
        gofmt -w $file
    done
done

# staging will be updated by other scripts
git checkout HEAD $K1/staging
# exceptions
#sed -i "/k8s.io\/kubernetes\/pkg\/api\"/d" $K1/pkg/api/v1/validation/validation.go
sed -i "/k8s.io\/kubernetes\/pkg\/api\/ref\"/d" pkg/proxy/userspace/proxier.go