// Public, read-only snapshot for regression testing the actual shared sample data.
// No account profiles or credentials are fetched; public actor IDs are anonymized.
import {writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
const root=resolve(import.meta.dirname,'../..');
const base='https://firestore.googleapis.com/v1/projects/accesstransit-b615b/databases/(default)/documents/sample_test/shared';
const actors=new Map();
function sanitize(v){if(typeof v==='string'&&/^[a-f0-9]{32}$/.test(v)){if(!actors.has(v))actors.set(v,`sample_actor_${actors.size+1}`);return actors.get(v);}if(Array.isArray(v))return v.map(sanitize);if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).map(([k,x])=>[k,sanitize(x)]));return v;}
const decode=v=>'nullValue'in v?null:'stringValue'in v?v.stringValue:'booleanValue'in v?v.booleanValue:'integerValue'in v?Number(v.integerValue):'doubleValue'in v?v.doubleValue:'timestampValue'in v?v.timestampValue:'arrayValue'in v?(v.arrayValue.values??[]).map(decode):Object.fromEntries(Object.entries(v.mapValue?.fields??{}).map(([k,x])=>[k,decode(x)]));
const collections={};
for(const c of ['buses','stations','routes','reports']){
  const r=await fetch(`${base}/${c}?pageSize=1000`);if(!r.ok)throw new Error(`Public ${c} read failed (${r.status}).`);
  const d=await r.json();if(d.nextPageToken)throw new Error('Snapshot needs pagination.');
  collections[c]=Object.fromEntries((d.documents??[]).map(doc=>[doc.name.split('/').at(-1),sanitize(Object.fromEntries(Object.entries(doc.fields).map(([k,v])=>[k,decode(v)])))]));
}
const output=resolve(root,'test/fixtures/shared_sample_search.json');await mkdir(resolve(root,'test/fixtures'),{recursive:true});
await writeFile(output,JSON.stringify({asOf:new Date().toISOString(),collections},null,2));
console.log(JSON.stringify({publicSnapshot:true,actorsAnonymized:actors.size,counts:Object.fromEntries(Object.entries(collections).map(([c,d])=>[c,Object.keys(d).length]))}));
