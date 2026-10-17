/** Preserve explicit document-ID sort direction; ignore only API metadata. */
export function indexKey(index,group){
  const fields=index.fields.map(f=>({fieldPath:f.fieldPath,...(f.order?{order:f.order}:{arrayConfig:f.arrayConfig})}));
  if(!fields.some(f=>f.fieldPath==='__name__'))fields.push({fieldPath:'__name__',order:fields.findLast(f=>f.order)?.order??'ASCENDING'});
  const collectionGroup=group??decodeURIComponent(index.name.split('/collectionGroups/')[1].split('/')[0]);
  return JSON.stringify({collectionGroup,queryScope:index.queryScope,fields});
}
export function indexCoverage(expected,indexes,fields){
  const ready=new Set(indexes.filter(i=>i.state==='READY').map(i=>indexKey(i)));
  const missingIndexes=expected.indexes.filter(i=>!ready.has(indexKey(i,i.collectionGroup)));
  const missingFields=[];
  for(const required of expected.fieldOverrides??[]){
    const field=fields.find(f=>f?.name?.endsWith(`/collectionGroups/${required.collectionGroup}/fields/${required.fieldPath}`));
    for(const wanted of required.indexes.filter(i=>i.queryScope==='COLLECTION_GROUP')){
      if(!(field?.indexConfig?.indexes??[]).some(i=>i.state==='READY'&&i.queryScope===wanted.queryScope&&
          i.fields?.some(f=>f.fieldPath===required.fieldPath&&f.order===wanted.order)))missingFields.push({...wanted,collectionGroup:required.collectionGroup,fieldPath:required.fieldPath});
    }
  }
  return {ready:missingIndexes.length===0&&missingFields.length===0,missingIndexes,missingFields};
}
