import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createServer} from 'node:http';
import {createModerationApi} from '../../server/moderation/api.mjs';
import {createNodeModerationHandler} from '../../server/moderation/node_handler.mjs';

test('real loopback HTTP adapter passes verified votes and rejects oversized/unauthenticated requests',async()=>{
  const calls=[];
  const api=createModerationApi({auth:{async verifyIdToken(token,revoked){assert.equal(token,'test-only');assert.equal(revoked,true);return {uid:'verified'};}},
    policy:{async voteReport(input){calls.push(input);return {hidden:false,duplicate:false,falseCount:1,confirmCount:0};}}});
  const server=createServer(createNodeModerationHandler({api,publicOrigin:'https://configured.test'}));
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  try {
    const url=`http://127.0.0.1:${server.address().port}/v2/reports/vote`;
    const headers={authorization:'Bearer test-only','content-type':'application/json'};
    const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({reportId:'r',value:'false',reason:'Working equipment'})});
    assert.equal(response.status,200);assert.equal((await response.json()).uid,'verified');assert.equal(calls[0].actorUid,'verified');
    assert.equal((await fetch(url,{method:'POST',headers:{'content-type':'application/json'},body:'{}'})).status,401);
    assert.equal((await fetch(url,{method:'POST',headers,body:'x'.repeat(5000)})).status,413);
    assert.equal(calls.length,1);
  } finally {server.closeAllConnections();await new Promise(resolve=>server.close(resolve));}
});

test('host origin is explicit HTTPS configuration',()=>{
  for(const publicOrigin of ['http://localhost','https://user:secret@host.test','https://host.test/path']) {
    assert.throws(()=>createNodeModerationHandler({api:()=>{},publicOrigin}),/fixed HTTPS/);
  }
});
