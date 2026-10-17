// Non-mutating verification of the real-Firebase localhost service.
import assert from 'node:assert/strict';
const origin='http://127.0.0.1:8788';
const health=await fetch(origin+'/healthz',{signal:AbortSignal.timeout(15000)});
const state=await health.json();
assert.equal(health.status,200,'Shared backend is not ready; do not claim activation.');
assert.equal(state.projectId,'accesstransit-b615b');assert.equal(state.mode,'real-firebase-localhost');assert.equal(state.ready,true);
for(const authorization of [null,'Bearer invalid-project-token']){
  const r=await fetch(origin+'/v2/account/status',{method:'POST',headers:{'content-type':'application/json',...(authorization?{authorization}:{})},body:'{}',signal:AbortSignal.timeout(15000)});
  assert.equal(r.status,401);assert.equal((await r.json()).error.code,'authentication-required');
}
console.log(JSON.stringify({projectId:state.projectId,ready:true,authRequired:true,invalidTokenRejected:true,userDataWrites:false}));
