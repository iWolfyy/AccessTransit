// Adapter for an initialized, trusted Firebase Admin Firestore instance.
// No credentials, initialization, deployment or public HTTP endpoint is included.
export function adminStore(db) {
  return {
    async page({collection,filters=[],after=null,limit=21,orderField='__name__',direction='asc'}) {
      let query=db.collection(collection);
      for(const [key,operator,value] of filters)query=query.where(key,operator,value);
      query=query.orderBy(orderField,direction);
      if(orderField!=='__name__')query=query.orderBy('__name__',direction);
      if(after)query=query.startAfter(orderField==='__name__'?after:await db.doc(collection+'/'+after).get());
      return (await query.limit(limit).get()).docs.map(d=>({id:d.id,data:d.data()}));
    },
    runTransaction: callback => db.runTransaction(transaction => callback({
      async get(path) { const snapshot = await transaction.get(db.doc(path)); return snapshot.exists ? snapshot.data() : null; },
      create(path, data) { transaction.create(db.doc(path), data); },
      set(path, data) { transaction.set(db.doc(path), data); },
      update(path, data) { transaction.update(db.doc(path), data); },
    })),
  };
}
