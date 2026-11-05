import { randomUUID } from 'node:crypto';
export const DAY = 48 * 60 * 1000;
export const places = [
 {x:3,y:4,type:'forge',name:'잿불 대장간',icon:'⚒'},
 {x:5,y:2,type:'library',name:'기억의 서재',icon:'▤'},
 {x:2,y:7,type:'grave',name:'이름의 묘지',icon:'†'},
 {x:7,y:5,type:'inn',name:'등불 여관',icon:'⌂'},
 {x:11,y:3,type:'ore',name:'철광맥',icon:'◆'},
 {x:12,y:8,type:'herb',name:'달빛 약초',icon:'✿'},
 {x:16,y:5,type:'ruin',name:'무너진 예배당',icon:'♜'}
];
export function createWorld(id, now=Date.now()) { return {id,last:now,time:0,people:{},graves:[],books:[],enemies:[{id:'wolf',x:14,y:5,hp:36,max:36,respawn:0}]}; }
export function spawn(w, owner, name='이름 없는 여행자') {
 if(Object.values(w.people).some(p=>p.owner===owner&&p.alive)) throw Error('이미 살아 있는 인물이 있습니다.');
 const p={id:randomUUID(),owner,name:String(name).trim().slice(0,24)||'여행자',x:5,y:5,hp:100,alive:true,ageDays:7200,limit:21600,bag:{ore:0,herb:0,sword:0,relic:0},skill:0,gold:12,policy:'rest',offline:false,seen:Date.now(),lastAction:0,entries:[],events:['잿불 마을에 도착했다.'],discoveries:[]}; w.people[p.id]=p; return p;
}
export function die(w,p,cause){if(!p.alive)return;p.alive=false;p.hp=0;p.offline=true;w.graves.push({id:p.id,name:p.name,cause,day:Math.floor(w.time/DAY)+1,x:p.x,y:p.y});w.books.push({author:p.name,entries:structuredClone(p.entries),last:[...p.events],cause});p.events.push(cause+'으로 삶이 끝났다.');}
export function advance(w,ms){
 if(!Number.isFinite(ms)||ms<0)throw Error('잘못된 시간입니다.');
 const before=Math.floor(w.time/DAY);w.time+=ms;const days=Math.floor(w.time/DAY)-before;
 for(const p of Object.values(w.people)){
  if(!p.alive)continue;
  // At most one lifetime is simulated; dead characters never keep producing.
  const livingDays=Math.min(days,Math.max(0,p.limit-p.ageDays));
  for(let i=0;i<livingDays;i++){
   if(p.offline){
    if(p.hp<40||p.policy==='rest'){p.hp=Math.min(100,p.hp+20);p.events.push('여관에서 쉬며 몸을 추슬렀다.');}
    else if(p.policy==='gather'){p.bag.herb=Math.min(20,p.bag.herb+2);p.events.push('근교에서 약초를 모아 보관했다.');}
    else if(p.policy==='work'){if(p.bag.ore>=2){p.bag.ore-=2;p.bag.sword++;p.skill++;p.events.push('대장간에서 철검 한 자루를 완성했다.');}else p.events.push('철이 부족해 대장간을 정리하고 쉬었다.');}
    else {if(p.skill<20)p.skill++;p.events.push('훈련장에서 기본기를 연습했다.');}
   }
   p.ageDays++;
   p.entries.push({day:before+i+1,text:p.events.length?p.events.join(' '):'별다른 일 없이 하루를 보냈다.'});p.events=[];
   if(p.ageDays>=p.limit){die(w,p,'노환');break;}
  }
 }
 for(const e of w.enemies)if(e.hp<=0&&w.time>=e.respawn){e.hp=e.max;}
}
const distance=(a,b)=>Math.abs(a.x-b.x)+Math.abs(a.y-b.y);
export function action(w,p,a,now=Date.now()){
 if(!p.alive)throw Error('사망한 인물입니다. 새로운 삶을 시작하세요.');
 if(a.type==='policy'){if(!['rest','work','gather','train'].includes(a.value))throw Error('잘못된 방침입니다.');p.policy=a.value;return '생활 방침을 저장했습니다.';}
 if(a.type==='logout'){if(p.x>9)throw Error('시제품에서는 마을로 돌아온 뒤 생활을 맡길 수 있습니다.');p.offline=true;return '생활을 맡겼습니다. 하루 경과 후 일기를 확인하세요.';}
 if(a.type==='resume'){p.offline=false;return '직접 조종을 시작합니다.';}
 if(p.offline)throw Error('먼저 직접 조종을 시작하세요.');
 if(now-p.lastAction<150)throw Error('잠시 후 다시 행동하세요.');p.lastAction=now;
 if(a.type==='move'){
  if(!Number.isInteger(a.dx)||!Number.isInteger(a.dy)||Math.abs(a.dx)+Math.abs(a.dy)!==1)throw Error('한 칸씩 이동할 수 있습니다.');
  p.x=Math.max(0,Math.min(19,p.x+a.dx));p.y=Math.max(0,Math.min(10,p.y+a.dy));return '';
 }
 if(a.type==='attack'){
  const e=w.enemies.find(e=>e.hp>0&&distance(e,p)<=2);if(!e)throw Error('공격할 적이 가까이 없습니다.');e.hp-=p.bag.sword?18:10;
  if(e.hp<=0){e.hp=0;e.respawn=w.time+DAY;p.gold+=8;p.events.push('예배당 길목의 늑대를 물리쳤다.');return '늑대 처치 · 8 은화';}
  p.hp-=14;if(p.hp<=0)die(w,p,'늑대와의 전투');return '늑대가 반격했다. 체력 -14';
 }
 if(a.type==='useHerb'){if(!p.bag.herb)throw Error('약초가 없습니다.');p.bag.herb--;p.hp=Math.min(100,p.hp+25);return '약초를 사용했다. 체력 +25';}
 const place=places.find(t=>t.type===a.target&&distance(t,p)<=1);if(!place)throw Error('시설이나 자원 옆으로 이동하세요.');
 switch(place.type){
  case 'ore':if(p.bag.ore>=20)throw Error('철광석 보관 한도입니다.');p.bag.ore++;p.events.push('북쪽 광맥에서 철광석을 캤다.');return '철광석 +1';
  case 'herb':if(p.bag.herb>=20)throw Error('약초 보관 한도입니다.');p.bag.herb++;p.events.push('근교에서 달빛 약초를 채집했다.');return '약초 +1';
  case 'forge':if(p.bag.ore<2)throw Error('철광석 2개가 필요합니다.');p.bag.ore-=2;p.bag.sword++;p.skill++;p.events.push('잿불 대장간에서 철검을 만들었다.');return '철검 제작 · 공격력 상승';
  case 'inn':p.hp=100;p.events.push('등불 여관에서 휴식을 취했다.');return '체력을 회복했습니다.';
  case 'ruin':if(w.enemies.some(e=>e.hp>0))throw Error('길목의 늑대를 먼저 처치하세요.');if(p.discoveries.includes('ruin'))return '이미 조사한 예배당입니다.';p.discoveries.push('ruin');p.bag.relic++;p.events.push('무너진 예배당에서 이름 없는 이의 유물을 발견했다.');return '오래된 유물 +1';
  case 'library':return '서재를 열었습니다.';
  case 'grave':return '묘지의 기록을 살펴봅니다.';
 }
 throw Error('알 수 없는 행동입니다.');
}
