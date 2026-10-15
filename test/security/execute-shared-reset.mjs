// Default is a read-only preflight. --apply requires the reviewed plan SHA-256.
import {createRequire} from 'node:module';
import {readFile, writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';

const projectId='accesstransit-b615b';
const root=resolve(import.meta.dirname,'../..');
const privateRoot=resolve(root,'.private/firebase-reset');
const file=name=>resolve(privateRoot,name);
const readJson=async path=>JSON.parse((await readFile(path,'utf8')).replace(/^\uFEFF/,''));
const digest=data=>createHash('sha256').update(data).digest('hex');
const rawPlan=await readFile(file('reset-plan.json'));
const plan=JSON.parse(rawPlan);
const planHash=digest(rawPlan);
const apply=process.argv[2]==='--apply';
if (apply && process.argv[3]!==planHash) throw new Error('Exact reviewed plan fingerprint required.');
if (!apply && process.argv.length>2) throw new Error('Unknown arguments; no writes performed.');
if (plan.projectId!==projectId) throw new Error('Wrong target project.');
for(const [path,hash] of [
  [resolve(root,'firestore.rules'),plan.rulesSha256],
  [resolve(plan.backupRoot,'firestore-backup.json'),plan.backups.firestoreSha256],
  [resolve(plan.backupRoot,'auth-backup.json'),plan.backups.authSha256],
  [file('new-auth-import.json'),plan.importSha256],
  [file('requested-accounts.json'),plan.accountInputSha256],
]) if (!hash || digest(await readFile(path))!==hash) throw new Error('Backup or reviewed inputs changed; prepare again.');
const config=await readJson(resolve(plan.backupRoot,'auth-config-backup.json'));
if (!(config.signIn?.hashConfig??config.signIn?.email?.hashConfig)?.signerKey) throw new Error('Auth restoration metadata missing.');
const require=createRequire(import.meta.url);
const auth=require('firebase-tools/lib/auth.js');
const account=auth.getGlobalDefaultAccount();
if (!account) throw new Error('Firebase CLI administrative sign-in required.');
const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
const prefix=`projects/${projectId}/databases/(default)/documents`;
const fsRoot=`https://firestore.googleapis.com/v1/${prefix}`;
const authRoot=`https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts`;
async function request(url,body,write=false) {
  if (write&&!apply) throw new Error('Remote mutation blocked in preflight.');
  const response=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
  if(!response.ok) throw new Error(`Administrative ${write?'write':'read'} failed (${response.status}); inspect private journal before retry.`);
  return response.json();
}
async function authUsers() {
  const users=[];let page;
  do {const url=new URL(`${authRoot}:batchGet`);url.searchParams.set('maxResults','1000');if(page)url.searchParams.set('nextPageToken',page);
    const result=await request(url);users.push(...(result.users??[]));page=result.nextPageToken;
  }while(page);return users;
}
async function firestoreDocuments(parent=fsRoot,documents=[]) {
  let pageToken;
  do {
    const page=await request(`${parent}:listCollectionIds`,{pageSize:1000,...(pageToken?{pageToken}:{})});
    for(const collection of page.collectionIds??[]) {
      let next;
      do {const url=new URL(`${parent}/${encodeURIComponent(collection)}`);url.searchParams.set('pageSize','1000');url.searchParams.set('showMissing','true');if(next)url.searchParams.set('pageToken',next);
        const result=await request(url);
        for(const d of result.documents??[]) {if(d.updateTime||d.createTime||d.fields)documents.push(d);await firestoreDocuments(`https://firestore.googleapis.com/v1/${d.name}`,documents);}
        next=result.nextPageToken;
      }while(next);
    }pageToken=page.nextPageToken;
  }while(pageToken);return documents;
}
function sameIds(actual,expected){return actual.length===expected.length&&actual.every(id=>expected.includes(id));}
let journal={planHash,phase:'prepared'};
try{journal=await readJson(file('reset-journal.json'));if(journal.planHash!==planHash)throw new Error('Different reset journal exists.');}catch(e){if(e.code!=='ENOENT')throw e;}
const savePhase=async phase=>{journal={...journal,phase,updatedAt:new Date().toISOString()};await writeFile(file('reset-journal.json'),JSON.stringify(journal,null,2));};
if(journal.phase==='prepared') {
  const docs=await firestoreDocuments();const users=await authUsers();
  if(!sameIds(users.map(u=>u.localId),plan.deleteAuth))throw new Error('Auth inventory changed; backup and review again.');
  const expected=new Map(plan.deleteFirestore.map(d=>[d.name,d.updateTime]));
  if(docs.length!==expected.size||docs.some(d=>expected.get(d.name)!==d.updateTime))throw new Error('Firestore changed since backup; backup and review again.');
  console.log(JSON.stringify({projectId,mode:apply?'apply':'read_only_preflight',planHash,deleteFirestore:docs.length,deleteAuth:users.length,createAuth:plan.accounts.length,createFirestore:plan.records.length}));
  if(!apply)process.exit(0);
  // Firestore's update-time preconditions make this deletion batch atomic.
  await request(`${fsRoot}:commit`,{writes:plan.deleteFirestore.map(d=>({delete:d.name,currentDocument:{updateTime:d.updateTime}}))},true);
  await savePhase('firestore_deleted');
}
if(!apply)throw new Error('Reset already started; inspect journal before resuming.');
if(journal.phase==='firestore_deleted') {
  const users=await authUsers();
  if(users.some(u=>!plan.deleteAuth.includes(u.localId)))throw new Error('Unexpected account after reset started.');
  if(users.length){const result=await request(`${authRoot}:batchDelete`,{localIds:users.map(u=>u.localId),force:true},true);if(result.errors?.length)throw new Error('Some old accounts were not deleted; inspect journal.');}
  await savePhase('auth_deleted');
}
if(journal.phase==='auth_deleted') {
  const existing=await authUsers();
  if(existing.some(u=>!plan.accounts.some(a=>a.uid===u.localId&&a.email===u.email)))throw new Error('Unexpected replacement account.');
  const input=await readJson(file('new-auth-import.json'));
  const missing=input.users.filter(u=>!existing.some(e=>e.localId===u.localId));
  if(missing.length){const result=await request(`${authRoot}:batchCreate`,{hashAlgorithm:'PBKDF2_SHA256',rounds:100000,users:missing,sanityCheck:true,allowOverwrite:false},true);if(result.error?.length||result.errors?.length)throw new Error('Account import partially failed; inspect journal.');}
  const users=await authUsers();if(!sameIds(users.map(u=>u.localId),plan.accounts.map(a=>a.uid)))throw new Error('Replacement account verification failed.');
  await savePhase('accounts_created');
}
function value(v){if(v===null)return {nullValue:'NULL_VALUE'};if(typeof v==='string')return {stringValue:v};if(typeof v==='boolean')return {booleanValue:v};if(typeof v==='number')return Number.isInteger(v)?{integerValue:String(v)}:{doubleValue:v};if(Array.isArray(v))return {arrayValue:{values:v.map(value)}};return {mapValue:{fields:Object.fromEntries(Object.entries(v).map(([k,x])=>[k,value(x)]))}};}
if(journal.phase==='accounts_created') {
  const docs=await firestoreDocuments();
  const paths=new Set(plan.records.map(r=>`${prefix}/${r.path}`));
  if(docs.some(d=>!paths.has(d.name)))throw new Error('Unexpected data after reset; refusing to overwrite.');
  const missing=plan.records.filter(r=>!docs.some(d=>d.name===`${prefix}/${r.path}`));
  if(missing.length)await request(`${fsRoot}:commit`,{writes:missing.map(r=>({update:{name:`${prefix}/${r.path}`,fields:Object.fromEntries(Object.entries(r.data).map(([k,v])=>[k,value(v)]))},currentDocument:{exists:false},...(r.path.startsWith('users/')?{updateTransforms:[{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'}]}:{})}))},true);
  await savePhase('catalogue_created');
}
const docs=await firestoreDocuments();const users=await authUsers();
if(docs.length!==plan.records.length||!sameIds(users.map(u=>u.localId),plan.accounts.map(a=>a.uid)))throw new Error('Final inventory verification failed.');
const input=await readJson(file('requested-accounts.json'));
await writeFile(file('new-account-credentials.txt'),plan.accounts.map(a=>`${a.role}: ${a.email}\nPassword: ${input.password}${a.role==='operator'?'\nOperator approval: pending identity/vehicle authorization':''}\n`).join('\n'));
await savePhase('complete');
console.log(JSON.stringify({projectId,phase:'complete',authAccounts:users.length,firestoreDocuments:docs.length,credentialsFile:file('new-account-credentials.txt')}));
process.exit(0);
