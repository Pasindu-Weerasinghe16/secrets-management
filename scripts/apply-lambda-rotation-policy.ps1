<#
Applies the inline IAM role policy for the Lambda rotation role.
Usage: .\apply-lambda-rotation-policy.ps1 [-RoleName <role>] [-PolicyFile <path>]
#>

[CmdletBinding()]
param(
    [string]$RoleName = "secrets-rotation-role-s4w61mr7",
    [string]$PolicyFile = "iam/lambda-rotation-secrets-policy.json"
)

Write-Host "Checking for AWS CLI..."
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI not found in PATH. Install AWS CLI v2 and re-run this script."; exit 1
}

$fullPolicyPath = Join-Path -Path (Get-Location) -ChildPath $PolicyFile
if (-not (Test-Path $fullPolicyPath)) {
    Write-Error "Policy file not found: $fullPolicyPath"; exit 1
}

Write-Host "Applying inline policy '$($fullPolicyPath)' to role '$RoleName'..."
aws iam put-role-policy --role-name $RoleName --policy-name LambdaRotationSecretsAccess --policy-document file://$fullPolicyPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to apply policy. See output above."; exit $LASTEXITCODE
}

Write-Host "Policy applied successfully. Verify with: aws iam get-role-policy --role-name $RoleName --policy-name LambdaRotationSecretsAccess"
