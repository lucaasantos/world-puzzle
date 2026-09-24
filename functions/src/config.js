import {getRemoteConfig} from 'firebase-admin/remote-config';
import {defaults, validateConfig} from './economy.js';

let cached = defaults, expires = 0;
export async function economyConfig() {
  if (process.env.FUNCTIONS_EMULATOR === 'true') return defaults;
  if (Date.now() < expires) return cached;
  try {
    const template = await getRemoteConfig().getServerTemplate({defaultConfig: {economy_json: JSON.stringify(defaults)}});
    cached = validateConfig(JSON.parse(template.evaluate().getString('economy_json')));
  } catch (error) {
    console.warn('Remote Config unavailable/invalid; retaining validated defaults', error.code ?? 'invalid-config');
  }
  expires = Date.now() + 300000;
  return cached;
}
