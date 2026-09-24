import {verify} from 'node:crypto';
let keys=[], expires=0;
export async function verifyAdCallback(url, allowedUnits, keyLoader=loadKeys) {
  const query=url.slice(url.indexOf('?')+1), marker=query.indexOf('&signature=');
  if(marker<0 || !/^[^&]+&key_id=\d+$/.test(query.slice(marker+11))) throw new Error('Malformed signature');
  const params=new URLSearchParams(query);
  for(const key of new Set(params.keys())) if(params.getAll(key).length!==1) throw new Error('Duplicate parameter');
  const p=Object.fromEntries(params);
  if(!allowedUnits.split(',').filter(Boolean).includes(p.ad_unit)) throw new Error('Unapproved ad unit');
  if(!Number.isFinite(Number(p.timestamp)) || Math.abs(Date.now()-Number(p.timestamp))>86400000) throw new Error('Expired callback');
  const publicKeys=await keyLoader(), key=publicKeys.find(k=>String(k.keyId)===p.key_id);
  if(!key || !verify('sha256',Buffer.from(query.slice(0,marker)),key.pem,Buffer.from(p.signature,'base64url'))) throw new Error('Invalid signature');
  if(!p.user_id || !p.custom_data || !p.transaction_id) throw new Error('Missing reward identity');
  return p;
}
async function loadKeys() {
  if(Date.now()<expires) return keys;
  const response=await fetch('https://www.gstatic.com/admob/reward/verifier-keys.json',{signal:AbortSignal.timeout(10000)});
  if(!response.ok) {const error=new Error('Key service unavailable');error.code='unavailable';throw error;}
  keys=(await response.json()).keys; expires=Date.now()+3600000;
  return keys;
}
