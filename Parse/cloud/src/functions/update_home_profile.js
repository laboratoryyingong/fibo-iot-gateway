const { requireHomeContext } = require('../lib/auth');
const { invalidArgument } = require('../lib/errors');

function cleanString(value, max) {
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== 'string') {
    throw invalidArgument('Expected a string value.');
  }
  return value.trim().slice(0, max);
}

// Updates the editable home + owner profile fields. Admin-only. Home name and
// location live on the Home object; the owner's display name and phone live on
// the calling user's _User record. Email is intentionally not mutated here
// (it's the login identity) and is treated as read-only by the client.
async function updateHomeProfile(request) {
  const { home } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['admin'],
  });

  const homeInput = request.params.home || {};
  const ownerInput = request.params.owner || {};

  const name = cleanString(homeInput.name, 120);
  const location = cleanString(homeInput.location, 200);
  if (name !== undefined) {
    if (name === '') {
      throw invalidArgument('Home name cannot be empty.');
    }
    home.set('name', name);
  }
  if (location !== undefined) {
    home.set('location', location);
  }
  await home.save(null, { useMasterKey: true });

  const fullName = cleanString(ownerInput.fullName, 120);
  const phone = cleanString(ownerInput.phone, 40);
  const user = request.user;
  if (fullName !== undefined) {
    user.set('fullName', fullName);
  }
  if (phone !== undefined) {
    user.set('phone', phone);
  }
  if (fullName !== undefined || phone !== undefined) {
    await user.save(null, { useMasterKey: true });
  }

  return {
    home: {
      homeId: home.get('homeId'),
      name: home.get('name'),
      location: home.get('location') || '',
    },
    owner: {
      fullName: user.get('fullName') || '',
      phone: user.get('phone') || '',
      email: user.get('email') || user.get('username') || '',
    },
  };
}

module.exports = { updateHomeProfile };
