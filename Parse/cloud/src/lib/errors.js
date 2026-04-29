function createCloudError(code, message, details = null) {
  return new Parse.Error(
    Parse.Error.SCRIPT_FAILED,
    JSON.stringify({ code, message, details }),
  );
}

function invalidArgument(message, details = null) {
  return createCloudError('invalid_argument', message, details);
}

function unauthenticated(message = 'A valid session is required.') {
  return createCloudError('unauthenticated', message);
}

function forbidden(message = 'User does not have access to this resource.') {
  return createCloudError('forbidden', message);
}

function notFound(message = 'Requested resource was not found.', details = null) {
  return createCloudError('not_found', message, details);
}

function conflict(message, details = null) {
  return createCloudError('conflict', message, details);
}

module.exports = {
  conflict,
  forbidden,
  invalidArgument,
  notFound,
  unauthenticated,
};
