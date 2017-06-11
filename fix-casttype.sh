set -o errexit
set -o nounset
set -o pipefail

typesgo=$(find $K1/vendor/k8s.io/api/ -name types.go)

for go in $typesgo; do
    sed -i "s|casttype=k8s.io/kubernetes/pkg/api/v1|casttype=k8s.io/api/core/v1|g" $go
done

file="$K1/staging/src/k8s.io/metrics/pkg/apis/metrics/v1alpha1/types.go"
sed -i "s|casttype=k8s.io/client-go/pkg/api/v1|casttype=k8s.io/api/core/v1|g" $file

file="$K1/staging/src/k8s.io/metrics/pkg/apis/metrics/v1alpha1/types.go"
sed -i "s|casttype=k8s.io/client-go/pkg/api/v1|casttype=k8s.io/api/core/v1|g" $file
sed -i "s|castkey=k8s.io/client-go/pkg/api/v1|castkey=k8s.io/api/core/v1|g" $file

