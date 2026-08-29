# Compute (ECS) Module

Runs a containerized service on Fargate - its own cluster, task definition,
service, security group, and CloudWatch log group. Built for microservices
workloads, as a companion to compute-ec2's web-server/bastion use case.

Every call creates a dedicated cluster rather than joining a shared one, to
keep each service's blast radius isolated from others.

## Required inputs

| Name | Type | Description |
|---|---|---|
| `team` | string | Owning team |
| `environment` | string | `dev`, `staging`, or `prod` |
| `purpose` | string | Short name for the service, e.g. `orders-api` |
| `subnet_ids` | list(string) | Subnets to run in, usually private |
| `container_image` | string | Full image URI to run |
| `container_port` | number | Port the container listens on |
| `execution_role_arn` | string | Role ECS uses to pull the image and write logs, from the iam module |
| `task_role_arn` | string | Role your application code runs as, from the iam module |

## Optional inputs

| Name | Default | Description |
|---|---|---|
| `cpu` | `256` | Fargate CPU units |
| `memory` | `512` | Fargate memory in MB |
| `desired_count` | `1` | How many task copies to keep running |
| `assign_public_ip` | `false` | Only needed if `subnet_ids` are public |
| `ingress_rules` | `[]` | Inbound rules to open. Empty by default |
| `tags` | `{}` | Extra tags merged on top of platform defaults |

## Outputs

| Name | Description |
|---|---|
| `cluster_name` / `service_name` | Reference for CI/CD deployments, alarms, autoscaling |
| `security_group_id` | Pass into relational-database's `allowed_security_group_ids` if this service needs a DB |
| `log_group_name` | Where this service's container logs land |

## Example usage

```hcl
module "execution_role" {
  source          = "../../../modules/iam"
  team            = "app-engineering"
  environment     = "dev"
  role_name       = "orders-api-execution"
  trusted_service = "ecs-tasks.amazonaws.com"
  policy_statements = [
    { actions = ["logs:CreateLogStream", "logs:PutLogEvents"], resources = ["*"] }
  ]
}

module "task_role" {
  source          = "../../../modules/iam"
  team            = "app-engineering"
  environment     = "dev"
  role_name       = "orders-api-task"
  trusted_service = "ecs-tasks.amazonaws.com"
  policy_statements = [
    { actions = ["secretsmanager:GetSecretValue"], resources = [module.orders_db.secret_arn] }
  ]
}

module "orders_api" {
  source              = "../../../modules/compute-ecs"
  team                = "app-engineering"
  environment         = "dev"
  purpose             = "orders-api"
  subnet_ids          = data.terraform_remote_state.platform_dev.outputs.private_subnet_ids
  container_image     = "123456789.dkr.ecr.us-east-1.amazonaws.com/orders-