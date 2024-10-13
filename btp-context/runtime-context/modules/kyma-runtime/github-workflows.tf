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

/*
resource "github_repository_file" "gh_workflow" {
  repository          = var.GITHUB_ACTIONS_REPOSITORY
  branch              = "main"
  commit_message      = "[Actions Bot] Update Github Actions workflow"
  overwrite_on_create = true
  file                = ".github/workflows/${var.GITHUB_ACTIONS_WORKFLOW}-${local.cluster_id}.yml"
  content             = data.local_file.gh_workflow.content

}
*/


data "github_repository" "gh_workflow" {
  full_name = var.GITHUB_ACTIONS_REPOSITORY
}

output "github_repository" {
  value = data.github_repository.gh_workflow.html_url
}


data "github_repository_file" "stale" {
  repository          = var.GITHUB_ACTIONS_REPOSITORY
  branch              = "main"
  file                = ".github/workflows/stale.yml"
}