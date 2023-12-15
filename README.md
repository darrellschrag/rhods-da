This Terraform script will deploy the Operators necessary for the Red Hat OpenShift Data Science functionality. The Terraform script will deploy the following Operators and their corresponding components.

1. Red Hat Pipelines Operator (optional) - If you plan on incorporating your AI work into Tekton pipelines, install this operator
2. Red Hat Node Discovery Feature Operator
    - Node Discovery Feature instance - this instance actually does the work of labeling nodes
3. Nvidia GPU Operator
    - Cluster Policy instance - this instance installs the GPU stack of daemonsets and pods
4. Red Hat Data Science Operator
    - Data Science Cluster instance - this instance installs the data science components

## Required Inputs
This Terraform script assumes the existence of an IBM Cloud ROKS cluster with at least 1 GPU worker node

## Required IAM access policies
You need the following permissions to run this module.

- IAM Services
  - **Kubernetes** service
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
| cluster_id | Name or Id of the target IBM Cloud OpenShift Cluster | `string` | none | yes |
| cluster_config_endpoint_type | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| deploy_pipeline_operator | If true, deploy the OpenShift Pipelines operator | `bool` | `false` | yes |
| region | IBM Cloud region | `string` | none | yes |
| nvidia_gpu_channel | The version of the NVIDIA GPU operator to install. Retrieve by: oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}' | `string` | none | yes |
| nvidia-gpu-startingcsv | Starting CSV value corresponding to the channel. Retrieve by: oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -o json &#124; jq -r '.status.channels[] &#124; select(.name == `nvidia_gpu_channel`) &#124; .currentCSV' | `string` | none | yes |
| nfd-instance-image-version | The version of the Node Feature Discovery instance image. Should be the OpenShift version you are using. Example: v4.13 | `string` | none | yes |
| number-gpu-nodes | The number of GPU nodes expected to be found in the cluster | `number` | none | yes |


