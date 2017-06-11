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

#============= section II, fix the original packages======================"
for gv in $GROUP_VERSIONS; do
    # git doesn't understand symlink, so use staging/src
    newFromKubeRoot="staging/src/k8s.io/api/${gv}"
    newAbsolute="$K1/$newFromKubeRoot"
    originFromKubeRoot="pkg/apis/${gv}"
    originAbsolute="$K1/$originFromKubeRoot"

    types=$(git grep "type" $newAbsolute/types.go | grep ":type" | awk '{print $2}')
    echo $types

    # version=${gv#*/}
    # echo $version
    gvNoHyphen=$(echo ${gv} | sed "s/\///g")
    echo $gvNoHyphen

    if [[ $gv == "certificates/v1beta1" ]]; then
        types="$types UsageDigitalSignature UsageKeyEncipherment KeyUsage CertificateSigningRequestSpec"
    fi
    if [[ $gv == "rbac/v1beta1" ]] || [[ $gv == "rbac/v1alpha1" ]]; then
        types="$types ServiceAccountKind UserKind GroupKind"
    fi
    if [[ $gv == "autoscaling/v2alpha1" ]]; then
        types="$types ResourceMetricSourceType"
    fi
    if [[ $gv == "apps/v1beta1" ]]; then
        types="$types RollingUpdateDeploymentStrategyType RecreateDeploymentStrategyType OrderedReadyPodManagement OnDeleteStatefulSetStrategyType"
    fi
    if [[ $gv == "batch/v2alpha1" ]]; then
        types="$types AllowConcurrent ForbidConcurrent"
    fi
    if [[ $gv == "extensions/v1beta1" ]]; then
        types="$types OnDeleteDaemonSetStrategyType RollingUpdateDaemonSetStrategyType RollingUpdateDeploymentStrategyType RecreateDeploymentStrategyType"
    fi
    if [[ $gv == "admissionregistration/v1alpha1" ]]; then
        types="$types Ignore"
    fi

    for t in $types; do
        # copied from pkg/api/v1/rewrite-pkg-api-v1.sh
        find $originAbsolute -maxdepth 1 -name "*.go" | xargs sed -i "s|\([][*{(&[:space:]]\)$t\>|\1$gvNoHyphen.$t|g"

        find $originAbsolute -maxdepth 1 -name "*.go" | xargs sed -i "s|$gvNoHyphen.$t\( *\)$gvNoHyphen.$t|$t\1$gvNoHyphen.$t|g"
        find $originAbsolute -maxdepth 1 -name "*.go" | xargs sed -i "s|$gvNoHyphen.$t:\( *\)$gvNoHyphen.$t|$t:\1$gvNoHyphen.$t|g"
    done 

    new_import_path="$gvNoHyphen \"k8s.io/api/${gv}\""

    files=$(find $originAbsolute -maxdepth 1 -name "*.go" | grep -v builder.go )
    for f in $files; do
        sed -i "s|import (|import (\n$new_import_path|g" $f
        goimports -w $f
    done

    # fix the generated conversion, conversion-gen would have made the same changes
    conversion=$originAbsolute/zz_generated.conversion.go
    sed -i "s|SchemeBuilder|localSchemeBuilder|g" $conversion

    group=${gv%/*}
    install=$originAbsolute/../install/install.go
    sed -i "s|\(ImportPrefix.*\"\)k8s.io/kubernetes/pkg/apis/$group|\1k8s.io/api/$group|g" $install
done

for gv in $GROUP_VERSIONS; do
    newFromKubeRoot="vendor/k8s.io/api/${gv}"
    newAbsolute="$K1/$newFromKubeRoot"
    originFromKubeRoot="pkg/apis/${gv}"
    originAbsolute="$K1/$originFromKubeRoot"
    
    version=${gv#*/}
    originRegisterDoc="$originAbsolute/register.go"
    sed -i '/func addKnownTypes/,$d' $originRegisterDoc
    sed -i "/Adds the list of known types to/d" $originRegisterDoc
    sed -i "s|addKnownTypes|$version.AddKnownTypes|g" $originRegisterDoc

    goimports -w $originRegisterDoc
done

# exceptions
find $K1/pkg/apis/admission/v1alpha1 -name "*.go" | xargs sed -i "s|k8s.io/kubernetes/pkg/apis/authentication/v1|k8s.io/api/authentication/v1|g"

sed -i 's|import "k8s.io/apimachinery/pkg/runtime"|\
import (\
"k8s.io/apimachinery/pkg/runtime"\
certificatesv1beta1 "k8s.io/api/certificates/v1beta1"\
)\
|g' $K1/pkg/apis/certificates/v1beta1/defaults.go

