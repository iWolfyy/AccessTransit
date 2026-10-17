import {createRequire} from 'node:module';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
const project='accesstransit-b615b';
const mode=process.argv[2]??'backup';
if(!['backup','verify'].includes(mode))throw Error('Use backup or verify.');
const require=createRequire(import.meta.url);
const auth=require('firebase-tools/lib/auth.js');
const account=auth.getGlobalDefaultAccount();
if(!account)throw Error('Firebase CLI authentication required.');
const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
async function get(path){const r=await fetch(`https://firebaserules.googleapis.com/v1/${path}`,{headers:{Authorization:`Bearer ${token.access_token}`}});if(!r.ok)throw Error(`Rules read failed (${r.status}).`);return r.json();}
const release=await get(`projects/${project}/releases/cloud.firestore`);
const ruleset=await get(release.rulesetName);
const source=ruleset.source?.files?.find(f=>f.name==='firestore.rules')?.content;
if(!source)throw Error('Deployed rules source missing.');
const directory=resolve(import.meta.dirname,'../../.private/admin-setup');
await mkdir(directory,{recursive:true});
if(mode==='backup')await writeFile(resolve(directory,`rules-before-${Date.now()}.json`),JSON.stringify({release,source},null,2));
const sha256=createHash('sha256').update(source).digest('hex');
if(mode==='verify'){
 const local=await readFile(resolve(import.meta.dirname,'../../firestore.rules'),'utf8');
 if(source.replaceAll('\r\n','\n')!==local.replaceAll('\r\n','\n'))throw Error('Deployed rules differ from local tested source.');
 await writeFile(resolve(directory,'rules-verification.json'),JSON.stringify({project,sha256,matchesLocal:true,checkedAt:new Date().toISOString()},null,2));
}
console.log(JSON.stringify({project,mode,sha256,matchesLocal:mode==='verify'}));process.exit(0);
