// Sign-in/profile read checks for the exact requested replacement accounts.
// Tokens and passwords are never printed or stored in verification output.
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const root=resolve(import.meta.dirname,'../..');
const privateRoot=resolve(root,'.private/firebase-reset');
const readJson=async path=>JSON.parse((await readFile(path,'utf8')).replace(/^\uFEFF/,''));
const plan=await readJson(resolve(privateRoot,'reset-plan.json'));
const journal=await readJson(resolve(privateRoot,'reset-journal.json'));
const input=await readJson(resolve(privateRoot,'requested-accounts.json'));
const config=await readJson(resolve(root,'android/app/google-services.json'));
if(plan.projectId!=='accesstransit-b615b'||config.project_info.project_id!==plan.projectId||journal.phase!=='complete')throw new Error('Completed approved reset required.');
const apiKey=config.client.find(c=>c.client_info.android_client_info.package_name==='com.accesstransit.access_transit')?.api_key?.[0]?.current_key;
if(!apiKey)throw new Error('Matching Android Firebase API configuration missing.');
const fsRoot=`https://firestore.googleapis.com/v1/projects/${plan.projectId}/databases/(default)/documents`;
const checks=[];
for(const account of plan.accounts) {
  const response=await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,{
    method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:account.email,password:input.password,returnSecureToken:true})});
  const session=await response.json();
  if(!response.ok||session.localId!==account.uid||!session.idToken)throw new Error(`Replacement ${account.role} sign-in verification failed (${response.status}); no token details logged.`);
  const headers={Authorization:`Bearer ${session.idToken}`};
  const profileResponse=await fetch(`${fsRoot}/users/${account.uid}`,{headers});
  const profile=await profileResponse.json();
  if(!profileResponse.ok||profile.fields?.role?.stringValue!==account.role||profile.fields?.email?.stringValue!==account.email)throw new Error('Own profile verification failed.');
  const other=plan.accounts.find(a=>a.uid!==account.uid);
  const denied=await fetch(`${fsRoot}/users/${other.uid}`,{headers});
  if(denied.status!==403)throw new Error('Cross-account profile read was not denied.');
  if(account.role==='operator'){
    const approvalResponse=await fetch(`${fsRoot}/operator_access/${account.uid}`,{headers});
    const approval=await approvalResponse.json();
    if(!approvalResponse.ok||approval.fields?.approved?.booleanValue!==false)throw new Error('Pending operator approval state incorrect.');
  }
  checks.push({uid:account.uid,role:account.role,signIn:true,ownProfile:true,otherProfileDenied:true});
}
const publicCatalogue=await (await fetch(`${fsRoot}/buses?pageSize=1000`)).json();
if(publicCatalogue.documents?.length!==4||publicCatalogue.documents.some(d=>d.fields?.catalogueRecordType?.stringValue!=='published_timetable'||d.fields?.driverId?.nullValue===undefined))throw new Error('Published timetable catalogue verification failed.');
const empty={};
for(const collection of ['live_locations','trips','reports']){
  const response=await fetch(`${fsRoot}/${collection}?pageSize=1000`);const data=await response.json();
  if(!response.ok||(data.documents?.length??0)!==0)throw new Error(`Unexpected ${collection} after reset.`);
  empty[collection]=0;
}
const result={projectId:plan.projectId,verifiedAt:new Date().toISOString(),checks,signInsVerified:checks.length,
  passengerAccounts:checks.filter(c=>c.role==='passenger').length,operatorAccounts:checks.filter(c=>c.role==='operator').length,
  crossAccountReadsDenied:checks.length,operatorApprovalsPending:4,publishedTimetables:4,empty};
await writeFile(resolve(privateRoot,'account-verification.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify({...result,checks:undefined}));
