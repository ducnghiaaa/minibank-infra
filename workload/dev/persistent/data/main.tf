# Aurora PostgreSQL Serverless v2 for the services (infra spec §8). KMS keys for `security` come later.

locals {
  name = "minibank-dev"
}

# persistent reads persistent: VPC and DB subnet group from the network stack
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "minibank-tfstate-701254204984"
    key    = "workload/dev/persistent/network/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# "Badge" SG: whatever carries it may reach Aurora. EKS nodes (ephemeral) attach it later,
# so this persistent stack never has to know about ephemeral security groups.
resource "aws_security_group" "db_clients" {
  name        = "${local.name}-db-clients"
  description = "Attach to anything allowed to connect to Aurora"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags        = { Name = "${local.name}-db-clients" }
}

resource "aws_vpc_security_group_egress_rule" "db_clients_all" {
  security_group_id = aws_security_group.db_clients.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# No egress rules: Aurora never opens connections; replies pass because SGs are stateful.
resource "aws_security_group" "aurora" {
  name        = "${local.name}-aurora"
  description = "Aurora PostgreSQL: 5432 from db-clients only"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags        = { Name = "${local.name}-aurora" }
}

resource "aws_vpc_security_group_ingress_rule" "aurora_from_clients" {
  security_group_id            = aws_security_group.aurora.id
  description                  = "from db-clients"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db_clients.id
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "${local.name}-aurora"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "16.15"
  database_name      = "account"
  port               = 5432

  # RDS creates and rotates the master password in Secrets Manager; only the DB bootstrap Job uses it
  master_username             = "minibank_admin"
  manage_master_user_password = true

  # services connect with 15-minute IAM tokens, no passwords (app spec §10)
  iam_database_authentication_enabled = true

  # encryption at rest can only be chosen at creation
  storage_encrypted = true

  db_subnet_group_name   = data.terraform_remote_state.network.outputs.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  serverlessv2_scaling_configuration {
    min_capacity             = 0 # sleeps when nobody is connected: no compute cost overnight
    max_capacity             = 2 # cost cap
    seconds_until_auto_pause = 300
  }

  backup_retention_period = 1
  copy_tags_to_snapshot   = true

  # layers against deleting the bank's data by mistake:
  deletion_protection       = true  # AWS refuses DeleteDBCluster
  skip_final_snapshot       = false # if deleted anyway, keep a last snapshot
  final_snapshot_identifier = "${local.name}-aurora-final"
  lifecycle {
    prevent_destroy = true # any plan that deletes or replaces it fails
    # auto minor upgrades move 16.15 forward; do not let Terraform try to downgrade it
    ignore_changes = [engine_version]
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier          = "${local.name}-aurora-1"
  cluster_identifier  = aws_rds_cluster.main.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  publicly_accessible = false

  auto_minor_version_upgrade = true

  lifecycle {
    ignore_changes = [engine_version]
  }
}
