function getCloudConfig() {
  return {
    awsRegion: process.env.FIBO_AWS_REGION || 'us-east-1',
    awsIdentityPoolId: process.env.FIBO_AWS_IDENTITY_POOL_ID || null,
    awsIdentityProvider:
      process.env.FIBO_AWS_IDENTITY_PROVIDER || 'parse.fibo.user',
    iotTopicPrefixBase: process.env.FIBO_IOT_TOPIC_PREFIX_BASE || 'fibo/v1',
    developerTokenMode: process.env.FIBO_AWS_DEVELOPER_TOKEN_MODE || 'todo',
  };
}

module.exports = { getCloudConfig };
