resource "random_string" "eks_cluster_name_suffix" {
  length  = 8
  special = false
  numeric = false
}

module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.name}-${random_string.eks_cluster_name_suffix.id}"
  kubernetes_version = "1.33"
  upgrade_policy = {
    support_type = "STANDARD"
  }
  endpoint_public_access = true

  # EKS Addons
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

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size = 2
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
    }
  }

  tags = local.tags
}

data "aws_caller_identity" "current" {}

resource "aws_eks_access_entry" "current_user" {
  cluster_name  = module.eks_al2023.cluster_name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "current_user" {
  cluster_name  = module.eks_al2023.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.current.arn

  access_scope {
    type = "cluster"
  }
}

output "eks_cluster_name" {
    value = module.eks_al2023.cluster_name
}