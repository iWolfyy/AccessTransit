// Mount behind a managed HTTPS listener/proxy. Does not start a server or read keys.
export function createNodeModerationHandler({api,publicOrigin}) {
  const origin=new URL(publicOrigin);
  if(origin.protocol!=='https:' || origin.username || origin.password || origin.search || origin.hash || origin.pathname!=='/') {
    throw Error('A fixed HTTPS public origin is required');
  }
  return async (req,res) => {
    function reject(status,code) {
      res.writeHead(status,{'content-type':'application/json','cache-control':'no-store','connection':'close'});
      res.end(JSON.stringify({error:{code}}));
    }
    try {
      if(!req.url?.startsWith('/') || req.url.startsWith('//')) return reject(400,'invalid-request');
      let authHeaders=0;
      for(let i=0;i<req.rawHeaders.length;i+=2) if(req.rawHeaders[i].toLowerCase()==='authorization') authHeaders++;
      if(authHeaders>1) return reject(400,'invalid-request');
      if(Number(req.headers['content-length'])>16384) return reject(413,'request-too-large');
      const chunks=[];let size=0;
      for await (const chunk of req) {
        size+=chunk.length;
        if(size>16384) return reject(413,'request-too-large');
        chunks.push(chunk);
      }
      const headers={};
      for(const key of ['authorization','content-type','origin','access-control-request-method','access-control-request-headers']) {
        const value=req.headers[key];if(typeof value==='string') headers[key]=value;
      }
      const request=new Request(new URL(req.url,origin),{method:req.method,headers,
        ...(['GET','HEAD'].includes(req.method) ? {} : {body:Buffer.concat(chunks)})});
      const response=await api(request);
      res.writeHead(response.status,Object.fromEntries(response.headers));
      res.end(Buffer.from(await response.arrayBuffer()));
    } catch(_) {
      if(!res.headersSent) reject(503,'service-unavailable'); else res.end();
    }
  };
}
