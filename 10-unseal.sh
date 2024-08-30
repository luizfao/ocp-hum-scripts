set -euo pipefail

echo unsealing vault on vault namespace

oc login ${CLUSTER_API} -u ${OCP_USER} -p ${OCP_PWD}

oc -n vault exec -ti vault-0 -- vault operator unseal 98m+o2ylRhVbOi+4o5ub6PbP344ocFUVORgSYeypMDjh
oc -n vault exec -ti vault-0 -- vault operator unseal 44Fn0wmQKcqA0zvZk+ICmtD5Q+LoFXLIQfhf6uMzfKF1
oc -n vault exec -ti vault-0 -- vault operator unseal 91cfekg9vOQXfOU/YAHUbZGYuHHGPtiCHgHxARNJZYgu

echo success vault unsealed!

echo done

