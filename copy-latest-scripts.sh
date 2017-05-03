set -o errexit
set -o nounset
set -o pipefail

cp $K1/rewrite-import-for-function-move.sh ./
cp $K1/pkg/api/v1/rewrite-pkg-api-v1.sh ./
cp $K1/root-rewrite-v1-imports.sh ./
cp $K1/pkg/apis/move-external-types-for-apis.sh ./


