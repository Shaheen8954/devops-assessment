
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )

  common_tags = {
    Project     = var.project_name
    Environment = "test"
    ManagedBy   = "Terraform"
  }
}

# VPC, public/private subnets, routing, IGW and NAT Gateway
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway = true
  single_nat_gateway = true

  # Public subnets can be discovered for external load balancers.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # Private subnets can be discovered for internal load balancers.
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.common_tags
}

# EKS cluster and managed worker nodes
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.project_name
  kubernetes_version = var.kubernetes_version

  vpc_id = module.vpc.vpc_id

  # Keep worker nodes and EKS control-plane network interfaces private.
  control_plane_subnet_ids = module.vpc.private_subnets
  subnet_ids               = module.vpc.private_subnets

  # Public API endpoint restricted to the configured administrator CIDR.
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = [var.admin_cidr]

  # Grant the identity running Terraform administrative cluster access.
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}

    eks-pod-identity-agent = {
      before_compute = true
    }

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      name           = "${var.project_name}-nodes"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      subnet_ids = module.vpc.private_subnets

      # Use an explicit, short IAM role name for worker nodes.
      iam_role_name            = "${var.project_name}-nodes"
      iam_role_use_name_prefix = false
    }
  }

  tags = local.common_tags
}
 