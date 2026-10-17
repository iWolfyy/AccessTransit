// Read-only preflight for the user's existing project. Never enables an API,
// associates a billing account, upgrades a plan, deploys code or reads user data.
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const auth=require('firebase-tools/lib/auth.js');
const projectId='accesstransit-b615b';
const account=auth.getGlobalDefaultAccount();
if(!account)throw Error('Firebase CLI sign-in is required. No credential supplied.');
const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
if(!token?.access_token)throw Error('Administrative read authentication unavailable.');
const response=await fetch(`https://cloudbilling.googleapis.com/v1/projects/${projectId}/billingInfo`,{
  method:'GET',headers:{Authorization:`Bearer ${token.access_token}`},
});
const data=await response.json();
if(!response.ok){
  console.log(JSON.stringify({projectId,readOnly:true,status:response.status,
    code:data.error?.status??'unavailable',
    reasons:(data.error?.details??[]).map(d=>d.reason).filter(v=>typeof v==='string')}));
  process.exitCode=1;
}else{
  console.log(JSON.stringify({projectId,readOnly:true,billingEnabled:data.billingEnabled===true,
    billingAccountLinked:typeof data.billingAccountName==='string'&&data.billingAccountName.length>0}));
}
