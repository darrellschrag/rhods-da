This Terraform script will deploy the Operators necessary for the Red Hat OpenShift AI functionality. The Terraform script will deploy the following Operators and their corresponding components.

1. Red Hat Pipelines Operator (optional) - If you plan on incorporating Tekton pipelines into your AI work, install this operator
2. Red Hat Node Discovery Feature Operator
    - Node Discovery Feature instance - this instance actually does the work of labeling nodes
3. Nvidia GPU Operator
    - Cluster Policy instance - this instance installs the GPU stack of daemonsets and pods
4. Red Hat OpenShift AI Operator
    - OpenShift AI instance - this instance installs the components

## Required Inputs
This Terraform script works in two ways. You can pre-create your cluster and then use this Terraform to install the opertors into your existing cluster. Or you can have the Terraform create a simple single zone cluster for you first and then it will apply the operators to that cluster.

## Required IAM access policies
You need the following permissions to run this module.

- IAM Services
  - **Kubernetes** service (to create and access a ROKS cluster)
      - `Administrator` platform access
      - `Manager` service access
  - **VPC Infrastructure** service (to create VPC resources)
      - `Administrator` platform access
      - `Manager` service access
  - **All Account Management** service (to create a resource group)
      - `Administrator` platform access
      - `Manager` service access

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, <1.6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.8.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.16.1 |

## Resources

| Name | Type |
|------|------|
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [helm_release.pipelines_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.nfd_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.nfd_instance](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.gpu_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_policy](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.rhods_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.data_science_cluster](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ibmcloud_api_key | APIkey that's associated with the account to use, set via environment variable TF_VAR_ibmcloud_api_key | `string` | none | yes |
| cluster-id | Name or Id of the target IBM Cloud OpenShift Cluster | `string` | none | yes |
| cluster-config-endpoint-type | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| deploy-pipeline-operator | If true, deploy the OpenShift Pipelines operator | `bool` | `false` | yes |
| region | IBM Cloud region | `string` | none | yes |
| nvidia-gpu-channel | The version of the NVIDIA GPU operator to install. Retrieve by: `oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}'` | `string` | none | yes |
| nvidia-gpu-startingcsv | Starting CSV value corresponding to the channel. Retrieve by inserting the gpu channel value into this command: `oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -o json &#124; jq -r '.status.channels[] &#124; select(.name == <nvidia_gpu_channel>`) &#124; .currentCSV' | `string` | none | yes |
| nfd-instance-image-version | The version of the Node Feature Discovery instance image. Should be the OpenShift version you are using. Example: v4.13 | `string` | none | yes |
| number-gpu-nodes | The number of GPU nodes expected to be found in the cluster. The number of nodes created if creating a cluster. | `number` | none | yes |

### The following inputs are only required if you want terraform to create a cluster. All below values must be provided if you want terraform to create a cluster and there is no default value

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create-cluster | Set to true if you want a new cluster created. Set to false to use a pre-existing cluster. | `bool` | `false` | no |
| resource-group | A new or pre-existing resource group where any VPC and cluster resources will be created | `string` | none | no |
| ocp-version | The OpenShift version of the new cluster. Use `ibmcloud ks versions` to get allowable values. Only use the numeric portion of the version (ex. 4.13.8) | `string` | none | no |
| prefix | A prefix that will be prepended to the name of all resources created | `string` | `"base-ocp-std"` | no |
| machine-type | If creating a new cluster, use this worker node type. Use `ibmcloud ks flavors --zone <zone>` to get the values | `string` | none | no |
| cos-instance | A pre-existing COS service instance where a bucket will be provisioned to back the ROKS internal registry | `string` | none | mo |

## Sample terraform.tfvars file

**NOTE:** pass in your `ibmcloud_api_key` in the environment variable `TF_VAR_ibmcloud_api_key`

```
cluster-id = "torgpu"
deploy-pipeline-operator = false
region = "ca-tor"
nvidia-gpu-channel = "v23.9"
nvidia-gpu-startingcsv = "gpu-operator-certified.v23.9.1"
nfd-instance-image-version = "v4.14"
number-gpu-nodes = 2
ocp-version = "4.14.8"
create-cluster = true
machine-type = "gx3.16x80.l4"
cos-instance = "Cloud Object Storage-drs"
```


