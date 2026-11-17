'use strict';
const $=id=>document.getElementById(id);
const scenes={adopt:['Adopción',0],home:['Casa',1],feed:['Cocina',2],bath:['Baño',3],shop:['Armario',4],groom:['Peluquería',5],walk:['Paseo',6],games:['Juegos',7],fruit:['Huerto saltarín',7],disc:['Frisbee',8],vet:['Consulta',1],care:['Cuidados',2]};
const styles=[['Ropa','Peto de pana',18],['Artículos','Pañuelo coral',10],['Colores','Pelaje plata',24],['Cortes','Corte pompón',30]];
let pet=null,screen='adopt',step=0,item=0,confirming=false,result='',resultFrom='home',run=null;
const newPet=(name,coins=0)=>({name,coins,v:[65,70,75,80],owned:[],equipped:[]});
const action=(label,fn,cls='primary',parent=$('controls'))=>{
 const b=document.createElement('button');b.type='button';b.textContent=label;b.className=cls;b.onclick=fn;parent.append(b);return b;
};
function row(){const r=document.createElement('div');r.className='row';$('controls').append(r);return r}
function grid(){const r=document.createElement('div');r.className='cards';$('controls').append(r);return r}
function position(i,n){return (i%n)*100/(n-1)+'% '+Math.floor(i/n)*100/(n-1)+'%'}
function card(id,parent){const b=action('',()=>go(id),'card',parent),t=document.createElement('div');t.className='thumb';
 const img=document.createElement('i');img.style.backgroundPosition=position(scenes[id][1],3);t.append(img);
 const label=document.createElement('span');label.textContent=scenes[id][0];b.append(t,label)}
function title(kind,name,desc){$('kind').textContent=kind;$('title').textContent=name;$('desc').textContent=desc}
function go(id){if(run){run.stop();run=null}screen=id;step=0;confirming=false;render()}
function sample(id){if(id==='adopt'){pet=null;go('adopt');return}if(!pet)pet=newPet('Miel',12);go(id)}
function setArt(i,wardrobe=false){const art=$('art'),n=wardrobe?2:3;art.style.backgroundImage='url(arte/'+(wardrobe?'armario':'escenas')+'.png)';art.style.backgroundSize=n*100+'% '+n*100+'%';art.style.backgroundPosition=position(i,n)}
function showResult(from,text){result=text;resultFrom=from;go('result')}
function change(index,n){pet.v[index]=Math.min(100,Math.max(0,pet.v[index]+n))}
function marks(total){const el=document.createElement('div');el.className='steps';el.setAttribute('aria-label',step+' de '+total);for(let i=0;i<total;i++){const m=document.createElement('i');m.className=i<step?'done':'';el.append(m)}$('controls').append(el);$('hud').textContent=step+' / '+total}
function render(){
 $('field').hidden=true;$('controls').replaceChildren();$('note').textContent='';$('hud').textContent='';
 $('cash').textContent=pet?pet.coins:0;const source=screen==='result'?resultFrom:screen;setArt(scenes[source][1]);$('place').textContent=scenes[source][0];
 $('back').style.visibility=screen==='adopt'||screen==='home'?'hidden':'visible';
 $('back').onclick=()=>go('home');document.querySelectorAll('#index button').forEach(b=>b.classList.toggle('active',b.dataset.key===screen));
 if(screen==='adopt'){
  title('Adopción','Tu caniche toy','Elige el nombre que tendrá en casa.');
  const input=document.createElement('input');input.id='petname';input.placeholder='Nombre de tu caniche';input.setAttribute('aria-label',input.placeholder);$('controls').append(input);
  const r=row();action('Sugerir nombre',()=>{input.value=['Miel','Nube','Coco'][(step++)%3]},'secondary',r);
  const adopt=()=>{const n=input.value.trim().normalize('NFC'),len=Array.from(new Intl.Segmenter('es',{granularity:'grapheme'}).segment(n)).length;
   if(!len||len>16||/[\u0000-\u001f\u007f]/u.test(n)){ $('note').textContent='Elige un nombre de 1 a 16 caracteres.';return}
   pet=newPet(n);go('home')};action('Adoptar',adopt,'primary',r);input.onkeydown=e=>{if(e.key==='Enter')adopt()};return;
 }
 if(screen==='home'){
  const labels=['Saciedad','Higiene','Ánimo','Energía'];const suggestions=['¿Le preparamos la comida?','¿Preparamos un baño?','¿Jugamos en el parque?','Un descanso en casa le sentará bien.'];
  title('En casa',pet.name,suggestions[pet.v.indexOf(Math.min(...pet.v))]);const s=document.createElement('div');s.className='stats';
  pet.v.forEach((n,i)=>{const m=document.createElement('div');m.className='meter';m.textContent=labels[i]+' · '+n;const bar=document.createElement('i');bar.style.setProperty('--value',n+'%');m.append(bar);s.append(m)});$('controls').append(s);
  const r=row();for(const [id,cl] of [['care','secondary'],['games','primary'],['shop','option']])action(scenes[id][0],()=>go(id),cl,r);return;
 }
 if(screen==='care'||screen==='games'){const games=screen==='games';title(games?'En el parque':'La rutina de '+pet.name,games?'A jugar':'Cuidados',games?'Elige dónde ganar monedas con tu caniche.':'Elige una actividad para compartir.');const g=grid();for(const id of games?['fruit','disc']:['feed','bath','groom','walk','vet'])card(id,g);return}
 if(screen==='shop'){
  const [cat,label,cost]=styles[item];setArt(item,true);title('Vestuario · '+cat,label,confirming?'Después de la compra tendrás '+(pet.coins-cost)+' monedas.':'Prueba el estilo en el espejo.');
  const tabs=grid();styles.forEach(([c],i)=>action(c,()=>{item=i;confirming=false;render()},i===item?'option sel':'option',tabs));
  const owned=pet.owned.includes(item),equipped=pet.equipped.includes(item);
  if(confirming){const r=row();action('Cancelar',()=>{confirming=false;render()},'secondary',r);action('Confirmar',()=>{if(!pet.owned.includes(item)&&pet.coins>=cost){pet.coins-=cost;pet.owned.push(item);pet.equipped.push(item)}confirming=false;render()},'primary',r)}
  else if(owned){action(equipped?'Quitar · equipado':'Equipar',()=>{pet.equipped=equipped?pet.equipped.filter(x=>x!==item):pet.equipped.concat(item);render()})}
  else if(pet.coins<cost){action('Jugar · faltan '+(cost-pet.coins)+' monedas',()=>go('games'))}
  else action('Comprar y usar · '+cost,()=>{confirming=true;render()});return;
 }
 if(screen==='result'){
  title('Resultado',resultFrom==='disc'||resultFrom==='fruit'?'¡Bien jugado!':'¡Qué bien, '+pet.name+'!',result);
  const r=row();if(resultFrom==='groom')action('Ver cortes',()=>{item=3;go('shop')},'secondary',r);
  if(['fruit','disc'].includes(resultFrom))action('Repetir',()=>go(resultFrom),'secondary',r);
  action('Volver a casa',()=>go('home'),'primary',r);return;
 }
 if(screen==='fruit'||screen==='disc'){const fruit=screen==='fruit';
  title('Juegos del parque',scenes[screen][0],fruit?'Salta los bancales y recoge las manzanas.':'Apunta al aro y lanza tres discos.');action('Jugar',()=>beginField(fruit));return}
 const routines={
  feed:['Hora de comer','Acerca el cuenco para cada bocado.',['Dar un bocado','Dar un bocado','Dar un bocado'],0,20],
  bath:['Un baño de espuma','Ayúdale a quedar limpio de cabeza a patas.',['Mojar','Enjabonar lomo','Enjabonar patas','Enjabonar pecho','Aclarar'],1,25],
  walk:['El sendero','Acompáñale en sus tres paradas.',['Ir a las flores','Ir al banco','Ir a la fuente'],2,15],
  groom:['Entre rizos','Cepilla los tres mechones antes de elegir un corte.',['Cepillar flequillo','Cepillar orejas','Cepillar lomo'],1,8],
  vet:['Una revisión','Acompaña al caniche durante la visita.',['Escuchar el corazón','Revisar las patas'],2,5]};
 const [name,desc,acts,i,gain]=routines[screen];title('Cuidar a '+pet.name,name,desc);marks(acts.length);
 const advance=()=>{if(++step===acts.length){const before=pet.v[i];change(i,gain);if(screen==='walk')change(3,-5);showResult(screen,['Saciedad','Higiene','Ánimo','Energía'][i]+' de '+before+' a '+pet.v[i]+'.')}else render()};
 action(acts[step],advance);
 if(screen==='groom')action('Probar cortes',()=>{item=3;go('shop')},'secondary');
}
function beginField(fruit){
 $('field').hidden=false;$('controls').replaceChildren();$('hud').textContent='';title('Juegos del parque',fruit?'Huerto saltarín':'Frisbee',fruit?'Toca para saltar.':'Arrastra hacia el aro o usa el lanzamiento guiado.');
 run=createField(fruit,$('field'),h=>$('hud').textContent=h,(score)=>{
  const reward=fruit?2+score:3+3*score;pet.coins+=reward;change(2,8);change(3,-6);showResult(fruit?'fruit':'disc','+'+reward+' monedas · '+score+(fruit?' frutas':' capturas')+' · Saldo '+pet.coins);
 });
 const r=row();action(fruit?'Saltar':'Lanzar al aro',()=>run.act(),'primary',r);const pause=action('Pausa',()=>{pause.textContent=run.pause()?'Continuar':'Pausa'},'secondary',r);
}
for(const id of ['adopt','home','care','feed','bath','walk','groom','shop','games','fruit','disc','vet']){
 const b=action(scenes[id][0],()=>sample(id),'',$('index'));b.dataset.key=id
}
$('size').onchange=()=>{const [w,h]=$('size').value.split(' × ').map(Number),d=$('device');d.style.setProperty('--w',w+'px');d.style.setProperty('--h',h+'px');d.style.setProperty('--top',({320:20,390:47,430:59})[w]+'px');d.style.setProperty('--bottom',w===320?'12px':'34px');d.classList.toggle('tiny',w===320)};
$('size').onchange();render();
