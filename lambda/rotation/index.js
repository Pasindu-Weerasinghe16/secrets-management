const AWS = require('aws-sdk');
const secretsmanager = new AWS.SecretsManager();

function generatePassword() {
  const length = 32;
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+';
  let res = '';
  for (let i = 0; i < length; i++) res += chars[Math.floor(Math.random() * chars.length)];
  return res;
}

exports.handler = async (event, context) => {
  console.log('Rotation event:', JSON.stringify(event));
  const step = event.Step;
  const secretId = event.SecretId;
  const token = event.ClientRequestToken;

  try {
    switch (step) {
      case 'createSecret':
        await createSecret(secretId, token);
        break;
      case 'setSecret':
        await setSecret(secretId, token);
        break;
      case 'testSecret':
        await testSecret(secretId, token);
        break;
      case 'finishSecret':
        await finishSecret(secretId, token);
        break;
      default:
        throw new Error(`Unknown step ${step}`);
    }
    console.log('Rotation step completed:', step);
  } catch (err) {
    console.error('Rotation error:', err);
    throw err;
  }
};

async function createSecret(secretId, token) {
  // Generate a new secret value and store it as a new version (AWSPENDING via ClientRequestToken)
  const newSecret = JSON.stringify({ password: generatePassword() });

  console.log('Putting secret value (pending) for', secretId);
  await secretsmanager.putSecretValue({
    SecretId: secretId,
    ClientRequestToken: token,
    SecretString: newSecret
  }).promise();
}

async function setSecret(secretId, token) {
  // In a real rotation you would update the external system here (DB, API provider).
  // This placeholder assumes the external system accepts the new secret.
  console.log('setSecret called; update external system with pending secret for', secretId);
  // TODO: implement update to the target system using the pending secret value
}

async function testSecret(secretId, token) {
  // Retrieve the pending secret and validate it works against the external system.
  console.log('testSecret called for', secretId);
  const res = await secretsmanager.getSecretValue({ SecretId: secretId, VersionId: token }).promise().catch(() => null);
  if (!res || !res.SecretString) {
    throw new Error('Pending secret not found for testing');
  }
  // TODO: validate connection using the secret (e.g., try DB connection). Placeholder assumes success.
}

async function finishSecret(secretId, token) {
  // Move the AWSCURRENT staging label to the new version (token)
  console.log('finishSecret: promoting pending secret to AWSCURRENT for', secretId);

  // Find current version(s)
  const desc = await secretsmanager.describeSecret({ SecretId: secretId }).promise();
  const versions = desc.VersionIdsToStages || {};
  const currentVersion = Object.keys(versions).find(v => versions[v].includes('AWSCURRENT'));

  // Promote pending to current
  await secretsmanager.updateSecretVersionStage({
    SecretId: secretId,
    VersionStage: 'AWSCURRENT',
    MoveToVersionId: token,
    RemoveFromVersionId: currentVersion
  }).promise();
}
