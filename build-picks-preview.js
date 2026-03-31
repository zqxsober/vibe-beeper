const fs = require("fs");
const picks = JSON.parse(fs.readFileSync("picked-sprites.json", "utf8"));

const config = {
  idle:    { title: "Snoozing", detail: "Out cold · 5m", anim: "Growing sleep bubbles" },
  working: { title: "Working...", detail: "Busy with · Read", anim: "Eyes dart + body typing" },
  done:    { title: "Done!", detail: "Fresh out the oven", anim: "Hat toss celebration" },
  error:   { title: "Error", detail: "Oof · rate limited", anim: "Meltdown drip" },
  approve: { title: "Allow?", detail: "Pretty please · Bash", anim: "Jumping alarm" },
  input:   { title: "Needs input", detail: "Psst · Which file?", anim: "Hand wave beckoning" },
};

let cards = "";
Object.keys(config).forEach(k => {
  const c = config[k];
  const id = k;
  cards += `
    <div class="card">
      <h2>${c.title}</h2>
      <div class="sub">${c.detail}</div>
      <div class="lcd"><canvas id="c${id}"></canvas><div class="lt"><div class="t">${c.title}</div><div class="d">${c.detail}</div></div></div>
      <div class="al">${c.anim}</div>
      <div class="fi" id="f${id}">Frame 1/4</div>
      <div class="ctrls">
        <button onclick="pv('${id}')"> &lt; </button>
        <button class="on" id="p${id}" onclick="tg('${id}')">Playing</button>
        <button onclick="nx('${id}')"> &gt; </button>
      </div>
    </div>`;
});

const html = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>CC-Beeper — Final Picks</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#1a1a1a;color:#c8d6a0;font-family:monospace;padding:20px}
h1{color:#c8d6a0;margin-bottom:20px;font-size:18px}
.states{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;max-width:960px}
.card{background:#2a2a2a;border-radius:12px;padding:16px;border:2px solid #3a3a3a}
.card h2{font-size:14px;margin-bottom:4px;color:#fff}
.sub{font-size:11px;color:#999;margin-bottom:12px}
.lcd{background:#b8c878;border-radius:8px;padding:12px;display:flex;align-items:center;gap:10px;min-height:80px}
canvas{image-rendering:pixelated;flex-shrink:0}
.lt{flex:1}.lt .t{font-size:14px;font-weight:900;color:#4a5a28}
.lt .d{font-size:9px;color:#4a5a28;opacity:.7;margin-top:2px}
.fi{font-size:10px;color:#666;margin-top:8px;text-align:center}
.ctrls{margin-top:8px;display:flex;gap:8px;justify-content:center}
.ctrls button{background:#3a3a3a;border:1px solid #555;color:#ccc;padding:4px 10px;border-radius:4px;cursor:pointer;font-size:11px}
.ctrls button:hover{background:#4a4a4a}
.ctrls button.on{background:#5a7a2a;border-color:#7a9a3a}
.al{font-size:10px;color:#777;margin-top:6px;text-align:center;font-style:italic}
</style></head><body>
<h1>CC-Beeper — Final Picks (from 60-icon set)</h1>
<div class="states">${cards}</div>
<script>
var PX=3,ON="#4a5a28";
var sprites=${JSON.stringify(picks)};
var st={};
${Object.keys(config).map(k => `st["${k}"]={f:0,p:true};draw(document.getElementById("c${k}"),sprites["${k}"][0]);`).join("\n")}
function draw(c,rows){var x=c.getContext("2d"),cols=rows[0].length;c.width=cols*PX;c.height=rows.length*PX;x.clearRect(0,0,c.width,c.height);x.fillStyle=ON;rows.forEach(function(row,r){for(var i=0;i<row.length;i++){if(row[i]==="#")x.fillRect(i*PX,r*PX,PX,PX)}})}
function upd(k){draw(document.getElementById("c"+k),sprites[k][st[k].f]);document.getElementById("f"+k).textContent="Frame "+(st[k].f+1)+"/"+sprites[k].length}
function nx(k){st[k].f=(st[k].f+1)%sprites[k].length;upd(k)}
function pv(k){st[k].f=(st[k].f-1+sprites[k].length)%sprites[k].length;upd(k)}
function tg(k){st[k].p=!st[k].p;var b=document.getElementById("p"+k);b.textContent=st[k].p?"Playing":"Paused";b.className=st[k].p?"on":""}
setInterval(function(){Object.keys(st).forEach(function(k){if(st[k].p)nx(k)})},450);
</script></body></html>`;

fs.writeFileSync("picks-preview.html", html);
console.log("Done");
