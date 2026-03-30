<#
Creates an IAM role for GitHub Actions OIDC and attaches a minimal inline policy.
Run from repo root: .\scripts\create-github-oidc-role.ps1
#>

[CmdletBinding()]
param(
    [string]$RoleName = "github-actions-secrets-access",
    [string]$TrustFile = "iam/github-oidc-trust-policy.json",
    [string]$PolicyFile = "iam/github-oidc-policy.json"
)

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI not found in PATH. Install AWS CLI v2 and re-run this script."; exit 1
}

$cwd = Get-Location
$trust = Join-Path $cwd $TrustFile
$policy = Join-Path $cwd $PolicyFile

if (-not (Test-Path $trust)) { Write-Error "Trust file not found: $trust"; exit 1 }
if (-not (Test-Path $policy)) { Write-Error "Policy file not found: $policy"; exit 1 }

Write-Host "Creating role '$RoleName' with trust policy $TrustFile..."
aws iam create-role --role-name $RoleName --assume-role-policy-document file://$trust --description "Role for GitHub Actions OIDC to read secrets"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to create role. It may already exist." }

Write-Host "Attaching inline policy $PolicyFile to role '$RoleName'..."
aws iam put-role-policy --role-name $RoleName --policy-name GitHubActionsSecretsAccess --policy-document file://$policy
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to attach policy."; exit $LASTEXITCODE }

Write-Host "Role creation complete. Role ARN:";
aws iam get-role --role-name $RoleName --query 'Role.Arn' --output text

Write-Host "Next steps:
- In the GitHub repository settings -> Actions -> General, add the role ARN as the 'Role to assume' or configure your workflow to use it.
- Ensure the OIDC provider exists in AWS account (token.actions.githubusercontent.com). See https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
"
