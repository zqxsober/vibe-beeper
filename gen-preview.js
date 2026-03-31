const fs = require("fs");
const src = fs.readFileSync("Sources/Widget/ScreenView.swift", "utf8");

function extractSprites(name, count) {
  const frames = [];
  for (let i = 1; i <= count; i++) {
    const varName = name + i;
    const re = new RegExp(`static let ${varName}:\\s*\\[String\\]\\s*=\\s*\\[([^\\]]+)\\]`, "s");
    const m = src.match(re);
    if (m) {
      const rows = m[1].match(/"([^"]+)"/g).map(s => s.replace(/"/g, ""));
      frames.push(rows);
    }
  }
  return frames;
}

const sprites = {
  idle: extractSprites("idle", 4),
  working: extractSprites("working", 4),
  done: extractSprites("done", 4),
  error: extractSprites("error", 4),
  approve: extractSprites("approve", 4),
  input: extractSprites("input", 4),
  listen: extractSprites("listen", 4),
  speak: extractSprites("speak", 4),
};

const config = {
  idle:    { title: "Snoozing", variants: ["Idle","Out cold","Lights off","Gone fishing","Dreaming"], dynamic: "5m", sep: " \u00B7 ", anim: "Sleep bubbles (4f loop)", flash: "none" },
  working: { title: "Working...", variants: ["Running","Poking","Busy with","Tinkering","Crunching"], dynamic: "Bash", sep: " \u00B7 ", anim: "Eyes dart + typing (4f loop)", flash: "none" },
  done:    { title: "Done!", variants: ["That's a wrap","Over to you","Go check","Your turn","Fresh out the oven"], dynamic: null, sep: null, anim: "Hat toss (4f loop)", flash: "10x on entry" },
  error:   { title: "Error", variants: ["Oops","Uh oh","Broke","Oof","Welp"], dynamic: "rate limited", sep: " \u00B7 ", anim: "Meltdown (4f loop)", flash: "10x on entry" },
  approve: { title: "Allow?", variants: ["Knocking","Requesting","Asking for","Let me use","Pretty please"], dynamic: "Bash", sep: " \u00B7 ", anim: "Jumping alarm (4f loop)", flash: "10x on entry" },
  input:   { title: "Needs input", variants: ["Asks","Says","Psst","Hey","Paging you"], dynamic: "Which file?", sep: " \u00B7 ", anim: "Hand wave beckoning (4f loop)", flash: "10x on entry" },
  listen:  { title: "Listening...", variants: ["Mic on","All ears","Go ahead","Tuned in","Copy that"], dynamic: null, sep: null, anim: "Antenna vibrate (4f loop)", flash: "continuous on/off" },
  speak:   { title: "Reading recap", variants: ["Catching you up","Here's what happened","Quick summary","While you were away","Last message"], dynamic: null, sep: null, anim: "Mouth + waves out (4f loop)", flash: "continuous on/off" },
};

function card(id, cfg) {
  const v = cfg.variants[Math.floor(Math.random() * cfg.variants.length)];
  const sub = cfg.dynamic ? v + cfg.sep + cfg.dynamic : v;
  return `<div class="card">
    <h2>${cfg.title}</h2>
    <div class="sub">${sub}</div>
    <div class="lcd"><canvas id="c${id}"></canvas><div class="lt"><div class="t">${cfg.title}</div><div class="d">${sub}</div></div></div>
    <div class="al">${cfg.anim}</div>
    <div class="flash-tag">${cfg.flash}</div>
    <div class="fi" id="f${id}">Frame 1/4</div>
    <div class="ctrls"><button onclick="pv('${id}')"> &lt; </button>
    <button class="on" id="p${id}" onclick="tg('${id}')">Playing</button>
    <button onclick="nx('${id}')"> &gt; </button></div></div>`;
}

let cards = "";
Object.entries(config).forEach(([k, c]) => { cards += card(k, c); });

const html = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>CC-Beeper LCD States Preview</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#1a1a1a;color:#c8d6a0;font-family:monospace;padding:20px}
h1{color:#c8d6a0;margin-bottom:20px;font-size:18px}
.states{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;max-width:1200px}
.card{background:#2a2a2a;border-radius:12px;padding:14px;border:2px solid #3a3a3a}
.card h2{font-size:14px;margin-bottom:4px;color:#fff}
.sub{font-size:11px;color:#999;margin-bottom:10px}
.lcd{background:#b8c878;border-radius:8px;padding:10px;display:flex;align-items:center;gap:8px;min-height:70px}
canvas{image-rendering:pixelated;flex-shrink:0}
.lt{flex:1}.lt .t{font-size:12px;font-weight:900;color:#4a5a28}
.lt .d{font-size:8px;color:#4a5a28;opacity:.7;margin-top:2px}
.fi{font-size:9px;color:#555;margin-top:6px;text-align:center}
.ctrls{margin-top:6px;display:flex;gap:6px;justify-content:center}
.ctrls button{background:#3a3a3a;border:1px solid #555;color:#ccc;padding:3px 8px;border-radius:4px;cursor:pointer;font-size:10px}
.ctrls button:hover{background:#4a4a4a}
.ctrls button.on{background:#5a7a2a;border-color:#7a9a3a}
.al{font-size:9px;color:#777;margin-top:6px;text-align:center;font-style:italic}
.flash-tag{font-size:8px;color:#997;text-align:center;margin-top:2px}
</style></head><body>
<h1>CC-Beeper — All 8 LCD States</h1>
<div class="states">${cards}</div>
<script>
var PX=3,ON="#4a5a28";
var sprites=${JSON.stringify(sprites)};
var st={};
Object.keys(sprites).forEach(function(k){
  st[k]={f:0,p:true};
  var c=document.getElementById("c"+k);
  if(c)draw(c,sprites[k][0]);
});
function draw(c,rows){var x=c.getContext("2d"),cols=rows[0].length;c.width=cols*PX;c.height=rows.length*PX;x.clearRect(0,0,c.width,c.height);x.fillStyle=ON;rows.forEach(function(row,r){for(var i=0;i<row.length;i++){if(row[i]==="#")x.fillRect(i*PX,r*PX,PX,PX)}})}
function upd(k){var s=st[k];draw(document.getElementById("c"+k),sprites[k][s.f]);document.getElementById("f"+k).textContent="Frame "+(s.f+1)+"/"+sprites[k].length}
function nx(k){var s=st[k];s.f=(s.f+1)%sprites[k].length;upd(k)}
function pv(k){var s=st[k];s.f=(s.f-1+sprites[k].length)%sprites[k].length;upd(k)}
function tg(k){var s=st[k];s.p=!s.p;var b=document.getElementById("p"+k);if(b){b.textContent=s.p?"Playing":"Paused";b.className=s.p?"on":""}}
setInterval(function(){Object.keys(st).forEach(function(k){if(st[k].p)nx(k)})},450);
</script></body></html>`;

fs.writeFileSync("sprite-preview.html", html);
console.log("Preview updated with " + Object.keys(sprites).length + " states");
