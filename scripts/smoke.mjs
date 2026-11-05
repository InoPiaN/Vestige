import assert from 'node:assert/strict';
async function call(path,b){const r=await fetch('http://127.0.0.1:4173/api/'+path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(b)});const s=await r.json();assert.equal(r.status,200,s.error);return s;}
const a=await call('join',{mode:'multi',name:'검증 여행자 A'}),b=await call('join',{mode:'multi',name:'검증 여행자 B'});
assert(b.others.some(p=>p.id===a.player.id));
const next=await call('action',{token:a.token,action:{type:'move',dx:1,dy:0}});
const view=await call('state',{token:b.token});assert.equal(view.others.find(p=>p.id===a.player.id).x,next.player.x);
const solo=await call('join',{token:a.token,mode:'single'});assert.equal(solo.others.length,0);assert.notEqual(solo.player.id,a.player.id);
await call('action',{token:a.token,action:{type:'policy',value:'gather'}});await call('action',{token:a.token,action:{type:'logout'}});
const day=await call('day',{token:a.token});assert.equal(day.player.bag.herb,2);assert.match(day.player.entries[0].text,/약초/);
console.log('PASS: two-client shared movement, isolated single world, offline gathering and diary through HTTP.');
