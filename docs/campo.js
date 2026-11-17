'use strict';
const poodleSprite=new Image(),parkPlate=new Image();
poodleSprite.src='arte/caniche.png';parkPlate.src='arte/parque.png';
function createField(fruit,canvas,hud,complete){
 const g=canvas.getContext('2d'),W=400,H=410;
 let active=true,paused=false,frame=0,last=performance.now(),elapsed=0,score=0,tries=0;
 let feet=307,vy=0,grounded=true,travel=0,safe=0,flight=null,drag=null;
 const visited=new Set(), targets=[[200,230],[112,207],[286,250]];
 const pads=Array.from({length:15},(_,i)=>({x:i*180-35,width:i?144:174,y:307-(i%3)*10}));
 const apples=Array.from({length:12},(_,i)=>({x:180+i*180,y:242-i%3*10}));
 const disk=(x,y,a,b,color)=>{g.fillStyle=color;g.beginPath();g.ellipse(x,y,a,b,0,0,Math.PI*2);g.fill()};
 function dog(x,y,size){if(poodleSprite.complete&&poodleSprite.naturalWidth)g.drawImage(poodleSprite,x-size/2,y-size,size,size)}
 function launch(x,y){if(paused||flight||!active)return;flight={x,y,t:0};drag=null}
 function act(){if(paused||!active)return;if(fruit){if(grounded){vy=-330;grounded=false}}else launch(...targets[tries])}
 function point(e){const r=canvas.getBoundingClientRect();return {x:(e.clientX-r.left)/r.width*W,y:(e.clientY-r.top)/r.height*H,id:e.pointerId}}
 canvas.onpointerdown=e=>{if(paused||flight)return;if(fruit){act();return}if(drag)return;drag=point(e);canvas.setPointerCapture(e.pointerId)};
 canvas.onpointerup=e=>{if(!drag||drag.id!==e.pointerId)return;const p=point(e),dist=Math.hypot(p.x-drag.x,p.y-drag.y);drag=null;if(dist>26)launch(p.x,p.y)};
 canvas.onpointercancel=()=>{drag=null};
 function tick(time){
  if(!active)return;const dt=paused?0:Math.min((time-last)/1000,0.06);last=time;elapsed+=dt;
  g.clearRect(0,0,W,H);
  if(parkPlate.complete&&parkPlate.naturalWidth){const w=parkPlate.naturalWidth/2;g.drawImage(parkPlate,fruit?0:w,0,w,parkPlate.naturalHeight,0,0,W,H)}
  if(fruit){
   travel+=dt*94;const old=feet;vy+=dt*740;feet+=vy*dt;
   grounded=false;
   for(const p of pads){
    const x=p.x-travel+75;
    if(x< -p.width||x>W)continue;
    g.fillStyle='#9e7449';g.fillRect(x,p.y,p.width,18);g.fillStyle='#6d8b4f';g.fillRect(x,p.y,p.width,6);
    if(travel>=p.x&&travel<=p.x+p.width&&old<=p.y+0.1&&feet>=p.y&&vy>=0){feet=p.y;vy=0;grounded=true;safe=p.x+10}
   }
   if(feet>H+50){travel=Math.max(0,safe);feet=260;vy=0}
   for(const [i,a] of apples.entries()){
    if(visited.has(i))continue;const x=a.x-travel+75;
    if(x<-12||x>W+12)continue;
    if(Math.hypot(x-75,a.y-(feet-29))<30){visited.add(i);score++;continue}
    disk(x,a.y,10,11,'#ae3433');disk(x-3,a.y-3,3,4,'#f48c73');disk(x+3,a.y-13,5,2,'#376649');
   }
   dog(75,feet+3,70);hud(Math.max(0,Math.ceil(30-elapsed))+' s · '+score+' frutas');
   if(elapsed>=30||travel>=2320){complete(score);return}
  }else{
   const [tx,ty]=targets[tries];disk(tx,ty,33,12,'#fff3bf');disk(tx,ty,24,8,'#759661');
   let dogX=tx-18,dogY=ty-8;
   if(drag){g.strokeStyle='#fff4c6';g.lineWidth=3;g.setLineDash([4,6]);g.beginPath();g.moveTo(200,365);g.lineTo(tx,ty);g.stroke();g.setLineDash([])}
   if(flight){
    flight.t+=dt/1.1;const t=Math.min(flight.t,1),x=200+(flight.x-200)*t,y=365+(flight.y-365)*t-126*4*t*(1-t);
    disk(x,y,21-8*t,7-3*t,'#c55238');disk(x,y-2,15-6*t,3,'#ffab69');dogY-=Math.sin(Math.PI*t)*16;
    if(flight.t>=1.15){if(Math.hypot(flight.x-tx,flight.y-ty)<=32)score++;tries++;flight=null;if(tries===3){complete(score);return}}
   }else{disk(200,365,30,8,'#ae4635');disk(200,362,23,5,'#fc9e62')}
   dog(dogX,dogY,94);hud('Tiro '+Math.min(tries+1,3)+'/3 · '+score+' aciertos');
  }
  if(paused){g.fillStyle='#35293d77';g.fillRect(0,0,W,H);g.fillStyle='#fff8e9';g.textAlign='center';g.font='bold 25px Georgia';g.fillText('En pausa',200,180)}
  frame=requestAnimationFrame(tick)
 }
 const blur=()=>{if(document.hidden&&!paused){paused=true;drag=null;const b=document.querySelector('#controls .secondary');if(b)b.textContent='Continuar'}};
 document.addEventListener('visibilitychange',blur);frame=requestAnimationFrame(tick);
 return {act,pause(){paused=!paused;drag=null;last=performance.now();return paused},stop(){active=false;cancelAnimationFrame(frame);document.removeEventListener('visibilitychange',blur);canvas.onpointerdown=canvas.onpointerup=canvas.onpointercancel=null}}
}
