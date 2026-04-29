const { randomUUID } = require('crypto');

function createBusinessId(prefix) {
  return `${prefix}_${randomUUID().replace(/-/g, '').slice(0, 12)}`;
}

module.exports = { createBusinessId };
