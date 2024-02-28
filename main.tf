########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  count                        = var.create-cluster ? 1 : 0
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.4"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource-group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource-group
}

########################################################################################################################
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  count                     = var.create-cluster ? 1 : 0
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group[0].resource_group_id
  address_prefix_management = "auto"
}

resource "ibm_is_public_gateway" "gateway" {
  count          = var.create-cluster ? 1 : 0
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc[0].id
  resource_group = module.resource_group[0].resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  count                    = var.create-cluster ? 1 : 0
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc[0].id
  resource_group           = module.resource_group[0].resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway[0].id
}


locals {

  kubeconfig = data.ibm_container_cluster_config.cluster_config.config_file_path

###############################
# Pipelines operator locals
###############################
  pipeline_operator_namespace = "openshift-operators"
  # local path to the helm chart
  chart_path_pipeline_operator = "openshift-pipelines"
  # helm release name
  helm_release_name_pipeline_operator = local.chart_path_pipeline_operator
  # operator subscription name
  subscription_name_pipeline_operator = "openshift-pipelines-operator"

###############################
# RHODS operator locals
###############################
  rhods_operator_namespace = "redhat-ods-operator"
  # local path to the helm chart
  chart_path_rhods_operator = "openshift-data-science"
  # helm release name
  helm_release_name_rhods_operator = local.chart_path_rhods_operator
  # operator subscription name
  subscription_name_rhods_operator = "rhods-operator"
  # local path to the helm chart
  chart_path_data_science_cluster = "data-science-cluster"
  # data science cluster helm release name
  helm_release_name_data_science_cluster = local.chart_path_data_science_cluster
  # data science cluster namespace
  rhods_cluster_namespace = "redhat-ods-applications"

###############################
# NFD operator locals
###############################
  nfd_operator_namespace = "openshift-nfd"
  # local path to the helm chart
  chart_path_nfd_operator = "nfd"
  # helm release name
  helm_release_name_nfd_operator = local.chart_path_nfd_operator
  # operator subscription name
  subscription_name_nfd_operator = "nfd"
  # local path to the helm chart
  chart_path_nfd_instance = "nfd-instance"
  # data science cluster helm release name
  helm_release_name_nfd_instance = local.chart_path_nfd_instance

###############################
# GPU operator locals
###############################
  gpu_operator_namespace = "nvidia-gpu-operator"
  # local path to the helm chart
  chart_path_gpu_operator = "nvidia-gpu-operator"
  # helm release name
  helm_release_name_gpu_operator = local.chart_path_gpu_operator
  # operator subscription name
  subscription_name_gpu_operator = "gpu-operator-certified"
  # local path to the helm chart
  chart_path_cluster_policy = "cluster-policy"
  # data science cluster helm release name
  helm_release_name_cluster_policy = local.chart_path_cluster_policy
}

data "ibm_resource_instance" "cos_instance" {
  count             = var.create-cluster ? 1 : 0
  name              = var.cos-instance
  service           = "cloud-object-storage"
}


resource "ibm_container_vpc_cluster" "cluster" {
  count              = var.create-cluster ? 1 : 0
  name               = var.cluster-id
  vpc_id             = ibm_is_vpc.vpc[0].id
  flavor             = var.machine-type
  worker_count       = var.number-gpu-nodes == null ? 2 : var.number-gpu-nodes < 2 ? 2 : var.number-gpu-nodes
  resource_group_id  = module.resource_group[0].resource_group_id
  cos_instance_crn   = data.ibm_resource_instance.cos_instance[0].id
  kube_version       = "${var.ocp-version}_openshift"
  update_all_workers = true
  zones {
    subnet_id = ibm_is_subnet.subnet_zone_1[0].id
    name      = "${var.region}-1"
  }
}

##############################################################################
# Retrieve information about all the Kubernetes configuration files and
# certificates to access the cluster in order to run kubectl / oc commands
##############################################################################
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = var.create-cluster ? ibm_container_vpc_cluster.cluster[0].id : var.cluster-id
  config_dir      = "${path.module}/kubeconfig"                                                             # See https://github.ibm.com/GoldenEye/issues/issues/552
  endpoint_type   = var.cluster-config-endpoint-type != "default" ? var.cluster-config-endpoint-type : null # null represents default
  admin           = true
}

##############################################################################
# Install the Pipelines operator if requested by the user
##############################################################################
resource "helm_release" "pipelines_operator" {
  depends_on = [data.ibm_container_cluster_config.cluster_config]
  count      = var.deploy-pipeline-operator == true ? 1 : 0

  name              = local.helm_release_name_pipeline_operator
  chart             = "${path.module}/chart/${local.chart_path_pipeline_operator}"
  namespace         = local.pipeline_operator_namespace
  create_namespace  = true
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set {
    name  = "operators.namespace"
    type  = "string"
    value = local.pipeline_operator_namespace
  }
  set {
    name  = "operators.subscription_name"
    type  = "string"
    value = local.subscription_name_pipeline_operator
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/approve-install-plan.sh ${local.subscription_name_pipeline_operator} ${local.pipeline_operator_namespace} 'wait'"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}

##############################################################################
# Install the NFD operator
# (will start at the same time as the pipelines operator if enabled)
##############################################################################
resource "helm_release" "nfd_operator" {
  depends_on = [data.ibm_container_cluster_config.cluster_config]

  name              = local.helm_release_name_nfd_operator
  chart             = "${path.module}/chart/${local.chart_path_nfd_operator}"
  namespace         = local.nfd_operator_namespace
  create_namespace  = true
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set {
    name  = "operators.namespace"
    type  = "string"
    value = local.nfd_operator_namespace
  }
  set {
    name  = "operators.subscription_name"
    type  = "string"
    value = local.subscription_name_nfd_operator
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/approve-install-plan.sh ${local.subscription_name_nfd_operator} ${local.nfd_operator_namespace} 'wait'"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}

##############################################################################
# Install the Node Discovery Feature instance
##############################################################################
resource "helm_release" "nfd_instance" {
  depends_on = [helm_release.nfd_operator]

  name              = local.helm_release_name_nfd_instance
  chart             = "${path.module}/chart/${local.chart_path_nfd_instance}"
  namespace         = local.nfd_operator_namespace
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set {
    name  = "operators.namespace"
    type  = "string"
    value = local.nfd_operator_namespace
  }
  set {
    name  = "operators.instance_version"
    type  = "string"
    value = var.nfd-instance-image-version
  }

  provisioner "local-exec" {
    command     = "${path.module}/chart/${local.chart_path_nfd_instance}/validate.sh ${var.number-gpu-nodes}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}

##############################################################################
# Install the NVIDIA GPU operator
# (depends on the NFD operator)
##############################################################################
resource "helm_release" "gpu_operator" {
  depends_on = [data.ibm_container_cluster_config.cluster_config, helm_release.nfd_instance]

  name              = local.helm_release_name_gpu_operator
  chart             = "${path.module}/chart/${local.chart_path_gpu_operator}"
  namespace         = local.gpu_operator_namespace
  create_namespace  = true
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set {
    name  = "operators.namespace"
    type  = "string"
    value = local.gpu_operator_namespace
  }
  set {
    name  = "operators.subscription_name"
    type  = "string"
    value = local.subscription_name_gpu_operator
  }
  set {
    name  = "operators.channel"
    type  = "string"
    value = var.nvidia-gpu-channel
  }
  set {
    name  = "operators.startingCSV"
    type  = "string"
    value = var.nvidia-gpu-startingcsv
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/approve-install-plan.sh ${local.subscription_name_gpu_operator} ${local.gpu_operator_namespace} 'approve'"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}

##############################################################################
# Install the Cluster Policy in the GPU operator
##############################################################################
resource "helm_release" "cluster-policy" {
  depends_on = [helm_release.gpu_operator]

  name              = local.helm_release_name_cluster_policy
  chart             = "${path.module}/chart/${local.chart_path_cluster_policy}"
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false
}


##############################################################################
# Install the RHODS operator
# (requires the NFD operator and GPU operator installs to be complete)
##############################################################################
resource "helm_release" "rhods_operator" {
  depends_on = [data.ibm_container_cluster_config.cluster_config, helm_release.cluster-policy, helm_release.nfd_instance]

  name              = local.helm_release_name_rhods_operator
  chart             = "${path.module}/chart/${local.chart_path_rhods_operator}"
  namespace         = local.rhods_operator_namespace
  create_namespace  = true
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set {
    name  = "operators.namespace"
    type  = "string"
    value = local.rhods_operator_namespace
  }
  set {
    name  = "operators.subscription_name"
    type  = "string"
    value = local.subscription_name_rhods_operator
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/approve-install-plan.sh ${local.subscription_name_rhods_operator} ${local.rhods_operator_namespace} 'wait'"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}

##############################################################################
# Install the Data Science Cluster in the RHODS operator
##############################################################################
resource "helm_release" "data_science_cluster" {
  depends_on = [helm_release.rhods_operator]

  name              = local.helm_release_name_data_science_cluster
  chart             = "${path.module}/chart/${local.chart_path_data_science_cluster}"
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false
}

##############################################################################
# Do some post install pod checking
##############################################################################
resource "null_resource" "pod_check" {
   depends_on = [helm_release.data_science_cluster]

   provisioner "local-exec" {
    command     = "${path.module}/scripts/pod_check.sh ${local.gpu_operator_namespace} ${var.number-gpu-nodes} ${local.rhods_cluster_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}

