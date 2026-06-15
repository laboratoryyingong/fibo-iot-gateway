#!/usr/bin/env node
/**
 * One-off cleanup: permanently removes every Scene with status === "archived"
 * (left behind by the old soft-delete) and all of their SceneActions.
 *
 * Zero dependencies — uses Node's built-in fetch (Node 18+) and the Parse REST
 * API with the master key. Reads config from the environment, falling back to
 * ../.env (PARSE_APP_ID, PARSE_MASTER_KEY, and DOMAIN or PARSE_SERVER_URL).
 *
 * Safe by default: prints what WOULD be deleted. Pass --yes to actually delete.
 *
 *   cd Parse/scripts
 *   node purge_archived_scenes.js          # dry run (preview)
 *   node purge_archived_scenes.js --yes    # really delete
 *
 * Master-key calls are IP-restricted (PARSE_SERVER_MASTER_KEY_IPS); if you get
 * "unauthorized", run this on the server host (or an allowed IP).
 */
'use strict';

const fs = require('fs');
const path = require('path');

function loadDotEnv() {
  const envPath = path.join(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) return;
  for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/i);
    if (!m) continue;
    const key = m[1];
    let val = m[2].trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    if (process.env[key] === undefined) process.env[key] = val;
  }
}

async function main() {
  loadDotEnv();

  const appId = process.env.PARSE_APP_ID;
  const masterKey = process.env.PARSE_MASTER_KEY;
  const serverUrl =
    process.env.PARSE_SERVER_URL ||
    (process.env.DOMAIN ? `https://${process.env.DOMAIN}/parse` : null);

  if (!appId || !masterKey || !serverUrl) {
    console.error(
      'Missing config. Need PARSE_APP_ID, PARSE_MASTER_KEY, and DOMAIN (or ' +
        'PARSE_SERVER_URL) in the environment or ../.env.',
    );
    process.exit(1);
  }

  const apply = process.argv.includes('--yes');
  const headers = {
    'X-Parse-Application-Id': appId,
    'X-Parse-Master-Key': masterKey,
    'Content-Type': 'application/json',
  };

  const req = async (method, route, where) => {
    let url = `${serverUrl}/${route}`;
    if (where) url += `?where=${encodeURIComponent(JSON.stringify(where))}&limit=1000`;
    const res = await fetch(url, { method, headers });
    if (!res.ok) {
      throw new Error(`${method} ${route} -> ${res.status} ${await res.text()}`);
    }
    return method === 'DELETE' ? {} : res.json();
  };

  console.log(`Server: ${serverUrl}`);
  console.log(apply ? 'Mode: DELETE (--yes)\n' : 'Mode: DRY RUN (pass --yes to delete)\n');

  const { results: scenes } = await req('GET', 'classes/Scene', {
    status: 'archived',
  });

  if (!scenes.length) {
    console.log('No archived scenes found. Nothing to do.');
    return;
  }

  let deletedScenes = 0;
  let deletedActions = 0;
  for (const scene of scenes) {
    const scenePtr = {
      __type: 'Pointer',
      className: 'Scene',
      objectId: scene.objectId,
    };
    const { results: actions } = await req('GET', 'classes/SceneAction', {
      scene: scenePtr,
    });

    console.log(
      `• Scene "${scene.name || scene.sceneId || scene.objectId}" ` +
        `(${scene.objectId}) + ${actions.length} action(s)`,
    );

    if (apply) {
      for (const a of actions) {
        await req('DELETE', `classes/SceneAction/${a.objectId}`);
        deletedActions += 1;
      }
      await req('DELETE', `classes/Scene/${scene.objectId}`);
      deletedScenes += 1;
    } else {
      deletedActions += actions.length;
      deletedScenes += 1;
    }
  }

  console.log(
    `\n${apply ? 'Deleted' : 'Would delete'}: ` +
      `${deletedScenes} scene(s), ${deletedActions} action(s).`,
  );
}

main().catch((err) => {
  console.error('Failed:', err.message);
  process.exit(1);
});
