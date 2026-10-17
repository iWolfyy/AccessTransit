// Additive, one-time import. Never execute the destructive Dart seedAll method.
// Default dry run; --apply commits only missing records within Sample/Test scope.
import {createRequire} from 'node:module';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {pastedFixtures,prefix} from './pasted-sample-fixtures.mjs';
const args=process.argv.slice(2);if(args.some(a=>!['--apply','--validate'].includes(a)))throw Error('Unknown argument');
const input=JSON.parse((await readFile(new URL('../../docs/catalogue-review/pasted-legacy-sample.json',import.meta.url),'utf8')).replace(/^\uFEFF/,''));
const fixture=pastedFixtures(input);if(args.includes('--validate')){console.log(JSON.stringify({mode:'offline',...fixture.counts}));process.exit(0);}
const require=createRequire(import.meta.url),auth=require('firebase-tools/lib/auth.js'),api=require('firebase-tools/lib/api.js'),{Firestore}=require('@google-cloud/firestore');
const account=auth.getProjectDefaultAccount(process.cwd())??auth.getGlobalDefaultAccount();if(!account?.tokens?.refresh_token)throw Error('Existing CLI sign-in required');
const projectId='accesstransit-b615b',db=new Firestore({projectId,preferRest:true,credentials:{type:'authorized_user',client_id:api.clientId(),client_secret:api.clientSecret(),refresh_token:account.tokens.refresh_token}});
const digest=x=>createHash('sha256').update(JSON.stringify(x)).digest('hex');
async function normal(){return Promise.all(['buses','routes','stations','service_runs','users'].map(async c=>[c,(await db.collection(c).orderBy('__name__').get()).docs.map(d=>[d.id,d.data()])]));}
try{
 const marker=db.doc(prefix+'fixture_batches/'+fixture.tag),existing=await marker.get();
 if(existing.exists){const rows=await db.getAll(...fixture.records.map(r=>db.doc(r.path)));if(rows.some(s=>!s.exists||s.data().sourceSha256!==input.sourceSha256))throw Error('Existing batch needs review; no overwrite performed');console.log(JSON.stringify({alreadyImported:true,verified:rows.length,counts:existing.data().counts,unchanged:true}));process.exitCode=0;}
 else{
 const before=await normal(),refs=fixture.records.map(r=>db.doc(r.path)),snapshots=await db.getAll(...refs);
 if(snapshots.some(s=>s.exists))throw Error('Existing import paths found: refusing to overwrite activity');
 const folder='.private/pasted-sample/'+fixture.tag;await mkdir(folder,{recursive:true});
 await writeFile(folder+'/plan.json',JSON.stringify(fixture,null,2));
 console.log(JSON.stringify({projectId,scope:prefix,apply:args.includes('--apply'),counts:fixture.counts,normalWrites:0}));
 if(args.includes('--apply')){
  if(refs.length+1>500)throw Error('Atomic batch too large');
  await writeFile(folder+'/before.json',JSON.stringify({normal:before,targets:snapshots.map(s=>({path:s.ref.path,exists:s.exists}))},null,2));
  await db.runTransaction(async tx=>{const rows=await tx.getAll(marker,...refs);if(rows.some(s=>s.exists))throw Error('Import changed concurrently');for(const r of fixture.records)tx.create(db.doc(r.path),r.data);tx.create(marker,{sourceSha256:input.sourceSha256,counts:fixture.counts,createdAt:new Date(),sampleScenario:true});});
  const after=await db.getAll(...refs);if(after.some(s=>!s.exists||s.data().sourceSha256!==input.sourceSha256))throw Error('Readback mismatch');
  if(digest(before)!==digest(await normal()))throw Error('Normal data changed concurrently; inspect without resetting');
  const receipt={verified:after.length,counts:fixture.counts,normalDataUnchanged:true,createdAt:new Date().toISOString()};await writeFile(folder+'/receipt.json',JSON.stringify(receipt,null,2));console.log(JSON.stringify(receipt));
 }
 }
}finally{await db.terminate();}
