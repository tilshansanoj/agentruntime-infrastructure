module "iam_roles" {
  source     = "../modules/iam"
  account_id = lookup(local.account_mapping, local.env)
  github_repo = "agentruntime"
  backend_s3_bucket_arn = "arn:aws:s3:::terraform-state-agentruntimelabs"
  is_root_account = false
  
  root_principals = [ 
    "arn:aws:iam::${local.account_mapping.agentruntime-root}:root"
   ]
}