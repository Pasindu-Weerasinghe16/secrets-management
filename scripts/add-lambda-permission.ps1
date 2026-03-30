<#
Adds a resource-based policy to a Lambda to allow AWS Secrets Manager to invoke it.
Usage:
  - Run after installing AWS CLI and configuring credentials.
  - Interactive: `.	ools\add-lambda-permission.ps1` and enter the Secret ARN when prompted.
  - Non-interactive: `.	ools\add-lambda-permission.ps1 -SecretArn "arn:..."`
#>
param(
    [string]$FunctionArn = "arn:aws:lambda:us-east-1:239500134025:function:secrets-rotation",
    [string]$SecretArn,
    [string]$Region = "us-east-1"
)

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI not found in PATH. Install AWS CLI v2 and re-run this script."
    exit 1
}

if (-not $SecretArn) {
    $SecretArn = Read-Host -Prompt "Enter the Secrets Manager secret ARN (eg arn:aws:secretsmanager:...:secret:NAME)"
}

if (-not $SecretArn) {
    Write-Error "Secret ARN is required. Exiting."
    exit 1
}

$statementId = "secretsmanager-invoke-$(Get-Date -Format yyyyMMddHHmmss)"

Write-Host "Adding permission to Lambda ($FunctionArn) to allow Secrets Manager invoke..."

$addCmd = @(
    'lambda', 'add-permission',
    '--function-name', $FunctionArn,
    '--statement-id', $statementId,
    '--action', 'lambda:InvokeFunction',
    '--principal', 'secretsmanager.amazonaws.com',
    '--source-arn', $SecretArn,
    '--region', $Region
)

$process = Start-Process -FilePath aws -ArgumentList $addCmd -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
if ($process.ExitCode -ne 0) {
    Write-Error "aws CLI returned exit code $($process.ExitCode). Check your credentials/permissions and try again."
    exit $process.ExitCode
}

Write-Host "Permission added. Fetching current resource policy..."
aws lambda get-policy --function-name $FunctionArn --region $Region

Write-Host "Done. If you see a policy statement with Principal secretsmanager.amazonaws.com, rotation should be able to invoke the function."
