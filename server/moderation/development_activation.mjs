/** This narrow activation never grandfathers nonzero totals automatically. */
export async function verifyZeroBaselines(profiles,hasSummary){
  if(profiles.length>100)throw Error('migration-review-required');
  for(const profile of profiles){
    if(typeof profile.uid!=='string'||!profile.uid||profile.uid.includes('/'))throw Error('invalid-profile');
    for(const key of ['points','reportsSubmitted','verifiedCount']){
      const n=profile[key]??0;
      if(!Number.isSafeInteger(n)||n!==0)throw Error('migration-review-required');
    }
    if(await hasSummary(profile.uid))throw Error('migration-review-required');
  }
}

export function alreadyActivated(m,a,rulesHash,now=new Date()){
  if(m?.enabled!==true&&a?.enabled!==true)return false;
  const time=m?.effectiveAt?.toDate?.()??m?.effectiveAt;
  if(m?.enabled===true&&a?.enabled===true&&m.policyVersion===2&&a.policyVersion===2&&
      m.localOnly!==true&&a.localOnly!==true&&m.backendMode==='localhost'&&a.backendMode==='localhost'&&
      m.reviewedRulesHash===rulesHash&&time instanceof Date&&Number.isFinite(+time)&&time<=now)return true;
  throw Error('activation-review-required');
}
