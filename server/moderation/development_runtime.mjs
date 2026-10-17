import {createHash} from 'node:crypto';

export const sharedProjectId='accesstransit-b615b';
export const sharedPort=8788;
export function developmentScopes(args = []) {
  if(args.some(a=>a!=='--sample'))throw Error('Unknown localhost option');
  return args.includes('--sample')?['normal','sample']:['normal'];
}
const instant=v=>v instanceof Date?v:v?.toDate?.();
const fingerprint=s=>createHash('sha256').update(s.replaceAll('\r\n','\n').trim()).digest('hex');

export function validateSharedEnvironment(env){
  for(const key of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST','FIREBASE_DATABASE_EMULATOR_HOST']){
    if(env[key])throw Error('Real-project localhost API refuses emulator environment overrides.');
  }
  for(const key of ['GOOGLE_CLOUD_PROJECT','GCLOUD_PROJECT']){
    if(env[key]&&env[key]!==sharedProjectId)throw Error('Real-project localhost API project mismatch.');
  }
  if(env.FIREBASE_CONFIG){
    let value;try{value=JSON.parse(env.FIREBASE_CONFIG);}catch{throw Error('Refusing an unreviewed Firebase configuration override.');}
    if(value.projectId!==sharedProjectId)throw Error('Real-project localhost API project mismatch.');
  }
}

/** Read-only: never creates activation documents or migrates existing balances. */
export async function inspectSharedReadiness({db,readRules,expectedRules,indexesReady,now=()=>new Date()}){
  if(db.projectId!==sharedProjectId)throw Error('Real-project localhost API project mismatch.');
  const [moderation,assistance,deployedRules,indexesActive]=await Promise.all([
    db.doc('moderation_config/active').get(),db.doc('assistance_config/active').get(),readRules(),indexesReady?.()??false,
  ]);
  const m=moderation.data(),a=assistance.data(),effectiveAt=instant(m?.effectiveAt);
  const reasons=[];
  if(indexesActive!==true)reasons.push('indexes-activation-required');
  if(typeof deployedRules!=='string'||fingerprint(deployedRules)!==fingerprint(expectedRules))reasons.push('rules-review-required');
  if(m?.enabled!==true||m.policyVersion!==2||m.localOnly===true||
      !effectiveAt||!Number.isFinite(+effectiveAt)||effectiveAt>now())reasons.push('moderation-activation-required');
  if(a?.enabled!==true||a.policyVersion!==2||a.localOnly===true)reasons.push('assistance-activation-required');
  return {projectId:sharedProjectId,ready:reasons.length===0,reasons,
    effectiveAt:effectiveAt&&Number.isFinite(+effectiveAt)?effectiveAt.toISOString():null,
    rulesMatch:!reasons.includes('rules-review-required')};
}

/** The loopback status endpoint contains no user data or credential values. */
export function guardedDevelopmentHandler({handler,readiness}){
  return async(req,res)=>{
    let state;
    try{state=await readiness();}catch{
      state={projectId:sharedProjectId,ready:false,reasons:['preflight-unavailable']};
    }
    if(req.url==='/healthz'&&req.method==='GET'){
      res.writeHead(state.ready?200:503,{'content-type':'application/json','cache-control':'no-store'});
      res.end(JSON.stringify({mode:'real-firebase-localhost',projectId:sharedProjectId,ready:state.ready,reasons:state.reasons}));return;
    }
    if(!state.ready){
      res.writeHead(503,{'content-type':'application/json','cache-control':'no-store'});
      res.end(JSON.stringify({error:{code:'service-unavailable'}}));return;
    }
    return handler(req,res);
  };
}
