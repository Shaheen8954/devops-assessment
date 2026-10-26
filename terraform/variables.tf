
variable "project_name" {
  description = "Name used to identify the project and its resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR range for the VPC"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Provide a valid IPv4 CIDR for the VPC."
  }
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR ranges for public subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_cidrs) >= 2 &&
      length(distinct(var.public_subnet_cidrs)) == length(var.public_subnet_cidrs) &&
      alltrue([
        for cidr in var.public_subnet_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "Provide at least two unique, valid IPv4 CIDRs for public subnets."
  }
}

variable "private_subnet_cidrs" {
  description = "IPv4 CIDR ranges for private subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.private_subnet_cidrs) >= 2 &&
      length(distinct(var.private_subnet_cidrs)) == length(var.private_subnet_cidrs) &&
      alltrue([
        for cidr in var.private_subnet_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "Provide at least two unique, valid IPv4 CIDRs for private subnets."
  }
}

variable "admin_cidr" {
  description = "Authorized public IPv4 CIDR for accessing the EKS API"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "Provide a valid IPv4 CIDR, such as 203.0.113.10/32."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "Provide at least one EC2 instance type."
  }
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number

  validation {
    condition     = var.node_min_size >= 1 && var.node_min_size == floor(var.node_min_size)
    error_message = "The minimum node count must be a positive integer."
  }
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number

  validation {
    condition     = var.node_max_size >= 1 && var.node_max_size == floor(var.node_max_size)
    error_message = "The maximum node count must be a positive integer."
  }
}

variable "node_desired_size" {
  description = "Initial desired number of EKS worker nodes"
  type        = number

  validation {
    condition = (
      var.node_desired_size >= var.node_min_size &&
      var.node_desired_size <= var.node_max_size &&
      var.node_desired_size == floor(var.node_desired_size)
    )
    error_message = "The desired node count must be an integer between the minimum and maximum node counts."
  }
}
