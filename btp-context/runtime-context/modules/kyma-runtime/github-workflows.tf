# https://stackoverflow.com/questions/75025642/create-files-in-a-github-repo-from-terraform-based-on-a-local-file

resource "local_file" "gh_workflow" {
//  filename = "${path.module}/assets/workflows/${var.GITHUB_ACTIONS_WORKFLOW}-${local.cluster_id}.yml"
  filename = "${path.module}/${var.GITHUB_ACTIONS_WORKFLOW}-${local.cluster_id}.yml"
  content  =  yamlencode(jsondecode(data.jq_query.gh_workflow.result)) // "(put YAML content in here)"

  depends_on = [ terraform_data.bootstrap-kymaruntime-bot ]  
}

data "local_file" "gh_workflow" {
  filename = local_file.gh_workflow.filename
}

output "gh_workflow_file" {
  value = data.local_file.gh_workflow.content
}


resource "github_repository_file" "gh_workflow" {
  depends_on          = [ data.github_repository.gh_workflow ]

  repository          = data.github_repository.gh_workflow.name //var.GITHUB_ACTIONS_REPOSITORY
  branch              = "main"
  commit_message      = "[Actions Bot] Update Github Actions workflow"
  commit_author       = "Terraform User"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  file                = ".github/workflows/${var.GITHUB_ACTIONS_WORKFLOW}-${local.cluster_id}.yml"
//  file                = ".github/workflows/${var.GITHUB_ACTIONS_WORKFLOW}-${local.context_id}.yml"


//  content             = data.local_file.gh_workflow.content
  content             =  yamlencode(jsondecode(data.jq_query.gh_workflow.result)) 

}


data "github_repository" "gh_workflow" {
  full_name = var.GITHUB_ACTIONS_REPOSITORY
}

output "github_repository" {
  value = data.github_repository.gh_workflow
}

/*
data "github_repository_file" "stale" {
  repository          = var.GITHUB_ACTIONS_REPOSITORY
  branch              = "main"
  file                = ".github/workflows/stale.yml"
}

output "github_repository_file" {
  value = data.github_repository_file.stale
}
*/

# https://stackoverflow.com/questions/64008302/question-re-terraform-and-github-actions-secrets

/*
data "github_actions_public_key" "repo_public_key" {
  repository = var.GITHUB_ACTIONS_REPOSITORY
}*/

resource "github_actions_secret" "gh_workflow" {
  depends_on       = [ data.github_repository.gh_workflow ]

  repository       = data.github_repository.gh_workflow.name 
  secret_name      = replace(local.subaccount_name, "-", "_") // replace("${var.GITHUB_ACTIONS_WORKFLOW}-${local.context_id}", "-", "_")
  plaintext_value  = "gh-${local.cluster_id}"
}

/*
resource "github_actions_secret" "gh_workflow" {
  repository       = "example_repository"
  secret_name      = "example_secret_name"
  encrypted_value  = var.some_encrypted_secret_string
}
*/
