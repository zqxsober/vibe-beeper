const fs = require("fs");
const picks = JSON.parse(fs.readFileSync("picked-sprites.json", "utf8"));

const listeningAlts = {
  "A: Ear + waves": {
    frames: [
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######..#.","...#......#.#.","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########.#","....######..#.","...#......#.#.","..##......##.#"],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."]
    ]
  },
  "B: Open mouth listen": {
    frames: [
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..##","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..##",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."]
    ]
  },
  "C: Head tilt + bars": {
    frames: [
      ["..............",".....######...","...##########.","..#..........#","..#..##..##..#","..#..........#","..#....##....#","..#..........#","...##########.",".....######...","....#......#..","...##......##."],
      ["..............","............#.",".....######.#.","...########.#.","..#..........#","..#..##..##..#","..#..........#","..#....##....#","...##########.",".....######...","....#......#..","...##......##."],
      ["..............","............#.","...........##.",".....######.#.","...########.#.","..#..##..##..#","..#..........#","..#....##....#","...##########.",".....######...","....#......#..","...##......##."],
      ["..............",".....######...","...##########.","..#..........#","..#..##..##..#","..#..........#","..#....##....#","..#..........#","...##########.",".....######...","....#......#..","...##......##."]
    ]
  }
};

const speakingAlts = {
  "A: Mouth + waves out": {
    frames: [
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########.#",".#..........#.",".#..##..##..#.",".#..........#.",".#.########.#.",".#.#......#.#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."]
    ]
  },
  "B: Boombox arms": {
    frames: [
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","############..","....######....","#.#.......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..############","....######....","...#.......#.#","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","############..","....######....","#.#.......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..############","....######....","...#.......#.#","..##......##.."]
    ]
  },
  "C: Megaphone": {
    frames: [
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######..#.","...#......####","..##.........."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########.#","....######..#.","...#......####","..##.........#"],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######..#.","...#......####","..##.........."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######..#.","...#......####","..##.........."]
    ]
  }
};

// Build all sprite data
const allSprites = {...picks};
Object.entries(listeningAlts).forEach(([k, v]) => {
  allSprites["listen_" + k.replace(/[^a-zA-Z0-9]/g, "")] = v.frames;
});
Object.entries(speakingAlts).forEach(([k, v]) => {
  allSprites["speak_" + k.replace(/[^a-zA-Z0-9]/g, "")] = v.frames;
});

// Build cards
function makeCard(id, title, subtitle, desc) {
  return `<div class="card"><h3>${title}</h3><div class="sub">${desc || ""}</div>
    <div class="lcd"><canvas id="c${id}"></canvas><div class="lt"><div class="t">${title}</div><div class="d">${subtitle}</div></div></div>
    <div class="fi" id="f${id}">Frame 1/4</div>
    <div class="ctrls"><button onclick="pv('${id}')"> &lt; </button>
    <button class="on" id="p${id}" onclick="tg('${id}')">Playing</button>
    <button onclick="nx('${id}')"> &gt; </button></div></div>`;
}

let body = '<h2 class="section">Listening (3 alternatives)</h2><p class="ctx">Recording voice — triggered by record button, ⌥R hotkey, or auto. Stops when recording ends or mute pressed.</p><div class="row">';
Object.entries(listeningAlts).forEach(([k, v]) => {
  const id = "listen_" + k.replace(/[^a-zA-Z0-9]/g, "");
  body += makeCard(id, "Listening...", "Go ahead · 3s", k.split(": ")[1]);
});
body += '</div>';

body += '<h2 class="section">Speaking (3 alternatives)</h2><p class="ctx">TTS reading aloud — triggered by VoiceOver auto-read or manual. Stops when TTS finishes or user interrupts.</p><div class="row">';
Object.entries(speakingAlts).forEach(([k, v]) => {
  const id = "speak_" + k.replace(/[^a-zA-Z0-9]/g, "");
  body += makeCard(id, "Speaking...", "Here's what I did...", k.split(": ")[1]);
});
body += '</div>';

body += '<h2 class="section">Current 6 Picks (reference)</h2><div class="row">';
const cfg = {idle:["Snoozing","Gone fishing · 5m"],working:["Working...","Tinkering · Bash"],done:["Done!","Your turn"],error:["Error","Oof · rate limited"],approve:["Allow?","Knocking · Bash"],input:["Needs input","Hey · Which file?"]};
Object.entries(cfg).forEach(([k, [t, d]]) => {
  body += makeCard(k, t, d, "");
});
body += '</div>';

const html = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>CC-Beeper — Voice States</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#1a1a1a;color:#c8d6a0;font-family:monospace;padding:20px}
h1{color:#c8d6a0;margin-bottom:8px;font-size:18px}
h2.section{color:#fff;font-size:16px;margin:32px 0 6px;padding-bottom:6px;border-bottom:1px solid #333}
h2.section:first-of-type{margin-top:16px}
p.ctx{color:#777;font-size:11px;margin-bottom:16px}
.row{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;max-width:960px;margin-bottom:32px}
.card{background:#2a2a2a;border-radius:12px;padding:14px;border:2px solid #3a3a3a}
.card h3{font-size:13px;margin-bottom:3px;color:#fff}
.card .sub{font-size:10px;color:#888;margin-bottom:10px;line-height:1.5}
.lcd{background:#b8c878;border-radius:8px;padding:10px;display:flex;align-items:center;gap:8px;min-height:70px}
canvas{image-rendering:pixelated;flex-shrink:0}
.lt{flex:1}.lt .t{font-size:13px;font-weight:900;color:#4a5a28}
.lt .d{font-size:8px;color:#4a5a28;opacity:.7;margin-top:2px}
.fi{font-size:9px;color:#555;margin-top:6px;text-align:center}
.ctrls{margin-top:6px;display:flex;gap:6px;justify-content:center}
.ctrls button{background:#3a3a3a;border:1px solid #555;color:#ccc;padding:3px 8px;border-radius:4px;cursor:pointer;font-size:10px}
.ctrls button:hover{background:#4a4a4a}
.ctrls button.on{background:#5a7a2a;border-color:#7a9a3a}
</style></head><body>
<h1>CC-Beeper — Listening & Speaking Alternatives</h1>
${body}
<script>
var PX=3,ON="#4a5a28";
var sprites=${JSON.stringify(allSprites)};
var st={};
Object.keys(sprites).forEach(function(k){
  st[k]={f:0,p:true};
  var c=document.getElementById("c"+k);
  if(c)draw(c,sprites[k][0]);
});
function draw(c,rows){var x=c.getContext("2d"),cols=rows[0].length;c.width=cols*PX;c.height=rows.length*PX;x.clearRect(0,0,c.width,c.height);x.fillStyle=ON;rows.forEach(function(row,r){for(var i=0;i<row.length;i++){if(row[i]==="#")x.fillRect(i*PX,r*PX,PX,PX)}})}
function upd(k){var s=st[k];var c=document.getElementById("c"+k);if(c)draw(c,sprites[k][s.f]);var f=document.getElementById("f"+k);if(f)f.textContent="Frame "+(s.f+1)+"/"+sprites[k].length}
function nx(k){var s=st[k];s.f=(s.f+1)%sprites[k].length;upd(k)}
function pv(k){var s=st[k];s.f=(s.f-1+sprites[k].length)%sprites[k].length;upd(k)}
function tg(k){var s=st[k];s.p=!s.p;var b=document.getElementById("p"+k);if(b){b.textContent=s.p?"Playing":"Paused";b.className=s.p?"on":""}}
setInterval(function(){Object.keys(st).forEach(function(k){if(st[k].p)nx(k)})},450);
</script></body></html>`;

fs.writeFileSync("voice-alts.html", html);
console.log("Done - 3 listening + 3 speaking + 6 existing picks");
