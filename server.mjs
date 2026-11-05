import http from 'node:http';
import {readFileSync,writeFileSync,mkdirSync,existsSync,renameSync} from 'node:fs';
import {randomUUID} from 'node:crypto';
import {createWorld,spawn,advance,action,places,DAY} from './game.mjs';
mkdirSync('data',{recursive:true});
let db=existsSync('data/worlds.json')?JSON.parse(readFileSync('data/worlds.json','utf8')):{worlds:{},sessions:{}};
function save(){writeFileSync('data/worlds.tmp',JSON.stringify(db));renameSync('data/worlds.tmp','data/worlds.json');}
function catchup(w){const now=Date.now();for(const p of Object.values(w.people))if(now-p.seen>15000)p.offline=true;advance(w,Math.max(0,now-w.last));w.last=now;}
const server=http.createServer(async(req,res)=>{
 try{
  if(req.url.startsWith('/api/')){
   if(req.method!=='POST')throw Error('POST 요청이 필요합니다.');
   if(req.headers.origin&&req.headers.origin!==`http://${req.headers.host}`)throw Error('허용되지 않은 출처입니다.');
   let raw='';for await(const chunk of req){raw+=chunk;if(raw.length>8192)throw Error('요청이 너무 큽니다.');}const b=JSON.parse(raw||'{}');
   let token=b.token;let session=db.sessions[token];
   if(req.url==='/api/join'){
    if(!session){token=randomUUID();session={owner:randomUUID()};db.sessions[token]=session;}
    session.world=b.mode==='multi'?'shared':`single-${session.owner}`;
    const w=db.worlds[session.world]??=createWorld(session.world);catchup(w);
    let p=Object.values(w.people).find(p=>p.owner===session.owner&&p.alive)||Object.values(w.people).filter(p=>p.owner===session.owner).at(-1);
    if(!p)p=spawn(w,session.owner,b.name);session.person=p.id;p.seen=Date.now();
   }
   if(!session||!session.world)throw Error('먼저 월드에 입장하세요.');
   const w=db.worlds[session.world];catchup(w);let p=w.people[session.person];let message='';
   if(req.url==='/api/action')message=action(w,p,b.action);
   else if(req.url==='/api/day'){if(w.id==='shared')throw Error('시간 진행은 싱글 실험에서만 가능합니다.');advance(w,DAY);message='세계에서 하루가 흘렀습니다.';}
   else if(req.url==='/api/new'){p=spawn(w,session.owner,b.name);session.person=p.id;message='새로운 삶을 시작합니다.';}
   else if(!['/api/join','/api/state'].includes(req.url))throw Error('없는 API입니다.');
   p.seen=Date.now();save();
   const others=Object.values(w.people).filter(x=>x.alive&&x.id!==p.id).map(x=>({id:x.id,name:x.name,x:x.x,y:x.y,offline:x.offline}));
   res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({token,message,player:p,others,day:Math.floor(w.time/DAY)+1,graves:w.graves,books:w.books,places,enemies:w.enemies,mode:w.id==='shared'?'multi':'single'}));return;
  }
  const routes={'/':['public/index.html','text/html'],'/app.js':['public/app.js','text/javascript'],'/style.css':['public/style.css','text/css']};const entry=routes[req.url];if(!entry){res.writeHead(404);res.end();return;}res.writeHead(200,{'Content-Type':entry[1]+'; charset=utf-8'});res.end(readFileSync(entry[0]));
 }catch(e){res.writeHead(400,{'Content-Type':'application/json'});res.end(JSON.stringify({error:e.message}));}
});
setInterval(()=>{for(const w of Object.values(db.worlds))catchup(w);save();},5000).unref();
server.listen(Number(process.env.PORT)||4173,'127.0.0.1',()=>console.log('Vestige: http://127.0.0.1:4173'));
