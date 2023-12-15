variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to use, set via environment variable TF_VAR_ibmcloud_api_key"
  type        = string
  sensitive   = true
  default     = null
}

variable "cluster_id" {
  type        = string
  description = "Name or Id of the target IBM Cloud OpenShift Cluster"
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "deploy_pipeline_operator" {
  type        = bool
  description = "If true, deploy the OpenShift Pipelines operator"
  default     = false
}

variable "region" {
  type        = string
  description = "IBM Cloud region"
}

variable "nvidia-gpu-channel" {
  type        = string
  description = "The version of the NVIDIA GPU operator to install. Retrieve by: oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}'"
}

variable "nvidia-gpu-startingcsv" {
  type        = string
  description = "Starting CSV value corresponding to the channel. Retrieve by: oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == '<channel>') | .currentCSV'"
}

variable "nfd-instance-image-version" {
  type        = string
  description = "The version of the Node Feature Discovery instance image. Should be the OpenShift version you are using. Example: v4.13"
}

variable "number-gpu-nodes" {
  type        = number
  description = "The number of GPU nodes expected to be found in the cluster"
}