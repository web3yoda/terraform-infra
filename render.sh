#!/bin/sh

CODE_BASE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# $1 input: path of terragrunt.yaml

tg_yaml_path=$1

resource_group_path=$(dirname ${tg_yaml_path})

resource_names=$(yq 'keys | .[]' ${tg_yaml_path})

for resource_name in ${resource_names}; do
    resource_path=${resource_group_path}/_${resource_name}
    mkdir -p ${resource_path}
    hcl_path=${resource_path}/terragrunt.hcl
    inputs_path=${resource_path}/inputs.yaml

    # gen temp inputs.yaml
    yq ".${resource_name}.inputs" ${tg_yaml_path} > ${inputs_path}

    # gen dependencie.x.yaml
    dependency_count=$(yq ".${resource_name}.dependencies | length" ${tg_yaml_path})
    if [ "$dependency_count" != 0 ];then
        for i in $(seq 0 $(($dependency_count-1))); do
            dependency_path=${resource_path}/dependency.$i.yaml
            yq ".${resource_name}.dependencies[$i]" ${tg_yaml_path} > ${dependency_path}
        done
    fi

    # render terragrunt.hcl
    yq ".${resource_name}" ${tg_yaml_path} \
        | gomplate -f ${CODE_BASE}/terragrunt.hcl.template -d ds=stdin:///data.yaml > ${hcl_path}
done