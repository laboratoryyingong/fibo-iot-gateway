const { invalidArgument } = require('./errors');

const PROFILE_STATE_FIELDS = {
  onoff_actuator: ['power'],
  dimmable_light: ['power', 'level'],
  color_light: ['power', 'level', 'color'],
  curtain: ['target_lift_percent'],
  door_lock: ['locked'],
};

const PROFILE_COMMAND_OPS = {
  curtain: ['open', 'close', 'stop'],
  button_remote: ['bind', 'unbind', 'clear_bindings'],
};

function validateSceneInput(input) {
  if (!input || typeof input !== 'object') {
    throw invalidArgument('`scene` payload must be provided.');
  }

  const { scene, actions } = input;
  if (!scene || typeof scene !== 'object') {
    throw invalidArgument('`scene` must be an object.');
  }

  if (typeof scene.name !== 'string' || scene.name.trim() === '') {
    throw invalidArgument('`scene.name` must be a non-empty string.');
  }

  if (!Array.isArray(actions) || actions.length === 0) {
    throw invalidArgument('`actions` must be a non-empty array.');
  }

  return {
    scene: {
      sceneId:
          typeof scene.sceneId === 'string' && scene.sceneId.trim() !== ''
            ? scene.sceneId.trim()
            : null,
      name: scene.name.trim(),
      icon: typeof scene.icon === 'string' ? scene.icon : null,
      enabled: scene.enabled !== false,
      executionMode:
          scene.executionMode === 'manual_and_automation'
            ? 'manual_and_automation'
            : 'manual_only',
      status: scene.status === 'archived' ? 'archived' : 'active',
    },
    actions: actions.map(normalizeSceneAction),
  };
}

function normalizeSceneAction(action, index) {
  if (!action || typeof action !== 'object') {
    throw invalidArgument(`Action at index ${index} must be an object.`);
  }

  if (
    typeof action.targetEndpointKey !== 'string' ||
    action.targetEndpointKey.trim() === ''
  ) {
    throw invalidArgument(
      `Action at index ${index} must provide \`targetEndpointKey\`.`,
    );
  }

  const actionType = action.actionType;
  if (!['desired_state', 'desired_command'].includes(actionType)) {
    throw invalidArgument(
      `Action at index ${index} must use \`desired_state\` or \`desired_command\`.`,
    );
  }

  if (!action.payload || typeof action.payload !== 'object') {
    throw invalidArgument(`Action at index ${index} must provide \`payload\`.`);
  }

  return {
    order: Number.isFinite(action.order) ? Number(action.order) : (index + 1) * 10,
    targetEndpointKey: action.targetEndpointKey.trim(),
    actionType,
    payload: action.payload,
  };
}

function validateActionAgainstDevice(action, device) {
  const profile = device.get('profile');
  const shadowName = device.get('shadowName');

  if (action.actionType === 'desired_state') {
    const state = action.payload.state;
    if (!state || typeof state !== 'object' || Array.isArray(state)) {
      throw invalidArgument('`payload.state` must be an object for desired_state.', {
        targetEndpointKey: action.targetEndpointKey,
      });
    }

    const invalidField = Object.keys(state).find((field) => field === 'toggle');
    if (invalidField) {
      throw invalidArgument('Non-deterministic scene field `toggle` is not allowed.', {
        targetEndpointKey: action.targetEndpointKey,
      });
    }

    const allowedFields = PROFILE_STATE_FIELDS[profile] || [];
    const unsupportedField = Object.keys(state).find(
      (field) => !allowedFields.includes(field),
    );
    if (unsupportedField) {
      throw invalidArgument('Scene payload contains an unsupported state field.', {
        profile,
        field: unsupportedField,
        shadowName,
      });
    }
    return;
  }

  const command = action.payload.command;
  if (!command || typeof command !== 'object' || Array.isArray(command)) {
    throw invalidArgument('`payload.command` must be an object for desired_command.', {
      targetEndpointKey: action.targetEndpointKey,
    });
  }

  if (typeof command.op !== 'string' || command.op.trim() === '') {
    throw invalidArgument('`payload.command.op` must be a non-empty string.', {
      targetEndpointKey: action.targetEndpointKey,
    });
  }

  const allowedOps = PROFILE_COMMAND_OPS[profile] || [];
  if (!allowedOps.includes(command.op)) {
    throw invalidArgument('Scene command op is not supported by the device profile.', {
      profile,
      op: command.op,
      shadowName,
    });
  }
}

module.exports = {
  validateActionAgainstDevice,
  validateSceneInput,
};
