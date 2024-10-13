# https://stackoverflow.com/questions/75025642/create-files-in-a-github-repo-from-terraform-based-on-a-local-file

resource "local_file" "gh_workflow" {
  filename = "${path.module}/assets/workflows/${var.GITHUB_ACTIONS_WORKFLOW}-${local.cluster_id}.yml"
  content  =  yamlencode(jsondecode(data.jq_query.gh_workflow.result)) // "(put YAML content in here)"
}

data "local_file" "example" {
  filename = local_file.example.filenamen
}

resource "github_repository_file" "workflow_dependabot" {
  repository          = var.GITHUB_ACTIONS_REPOSITORY
  branch              = "main"
  commit_message      = "[Actions Bot] Update Github Actions workflow"
  overwrite_on_create = true
  file                = ".github/workflows/${var.GITHUB_ACTIONS_WORKFLOW}-${local.cluster_id}.yml"
  content             = data.local_file.gh_workflow.content
}