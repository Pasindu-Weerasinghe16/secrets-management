$ErrorActionPreference = 'Stop'

# Seeds example secrets into the local dev Vault container.
# No real secrets should be used here.

$composeFile = Join-Path $PSScriptRoot "..\vault\dev\docker-compose.yml"

function Invoke-VaultInContainer {
    param(
        [Parameter(Mandatory = $true)][string[]]$Args
    )

    # Use docker compose exec to run Vault CLI inside the container.
    $argsJoined = $Args -join ' '
    docker compose -f $composeFile exec -T vault sh -lc "export VAULT_ADDR=http://127.0.0.1:8200; export VAULT_TOKEN=root; vault $argsJoined"
}

Write-Host "Seeding dev Vault secrets..."

# Ensure Vault is running
$running = docker ps --filter "name=secrets-management-vault-dev" --format "{{.Names}}"
if (-not $running) {
    Write-Host "Vault container not running; starting via docker compose..."
    docker compose -f $composeFile up -d
}

# Enable KV v2 at secret/ (idempotent)
try {
    Invoke-VaultInContainer -Args @('secrets', 'enable', '-path=secret', 'kv-v2') | Out-Null
} catch {
    # In dev mode, enabling twice returns a non-zero; ignore if already enabled
}

# Write example secrets
Invoke-VaultInContainer -Args @('kv', 'put', 'secret/database/config', 'username=admin', 'password=example-password') | Out-Null
Invoke-VaultInContainer -Args @('kv', 'put', 'secret/api/credentials', 'key=example-api-key') | Out-Null

Write-Host "Done. Example paths:"
Write-Host "- secret/database/config"
Write-Host "- secret/api/credentials"
