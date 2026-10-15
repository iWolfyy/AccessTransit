// Generate the scoped rehearsal rules from the original policy, never loosen it.
import {readFile,writeFile} from 'node:fs/promises';
const path=new URL('../../firestore.rules',import.meta.url);
const marker='    // BEGIN GENERATED SAMPLE TEST POLICY';
const current=await readFile(path,'utf8');
const base=(current.includes(marker)?current.slice(0,current.indexOf(marker))+'  }\n}\n':current).replaceAll('\r\n','\n');
const header='  match /databases/{database}/documents {\n';
const start=base.indexOf(header)+header.length;
if(start<header.length || !base.endsWith('  }\n}\n'))throw new Error('Unexpected rules structure.');
let body=base.slice(start,-6);
body=body.replaceAll('/databases/$(database)/documents/','/databases/$(database)/documents/sample_test/shared/');
// Existing same-project accounts authenticate; approval exists only in this scope.
body=body.replace('function signedIn() { return request.auth != null; }',
  'function signedIn() { return request.auth != null && exists(/databases/$(database)/documents/sample_test/shared/users/$(request.auth.uid)); }');
const scoped=body.split('\n').map(line=>line.trim()?'  '+line:'').join('\n');
const generated=base.slice(0,-6)+marker+'\n    // Source: root policy above; regenerate with test/security/generate-sample-rules.mjs.\n    match /sample_test/shared {\n'+scoped+'\n    }\n  }\n}\n';
await writeFile(path,generated);
console.log('Generated isolated sample_test/shared policy; original policy preserved.');
