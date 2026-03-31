const fs = require("fs");
const html = fs.readFileSync("/Users/vcartier/Desktop/CC-Beeper/all-alts.html", "utf8");
const match = html.match(/var STATES = (\[[\s\S]*?\]);/);
const states = eval(match[1]);

// Start from the 60-icon originals
const picks = {
  idle: states[0].alts[0].frames,       // Sleep bubbles
  working: states[1].alts[0].frames,     // Eyes dart + typing
  done: states[2].alts[8].frames,        // Hat toss
  error: states[3].alts[4].frames,       // Meltdown
  approve: states[4].alts[2].frames,     // Jumping alarm
  input: states[5].alts[0].frames,       // Hand wave
};

// TWEAK 1: Idle — same base, just make bubbles bigger/rounder
// Keep frames 1-2 from original, enlarge bubbles in frames 3-4
picks.idle[2] = [  // Frame 3: medium round bubble (2x2 solid) instead of tiny dot
  "..........##..",
  "....######.##.",
  "..##########..",
  ".#..........#.",
  ".#.###..###.#.",
  ".#..........#.",
  ".#....##....#.",
  ".#..........#.",
  "..##########..",
  "..##########..",
  "..............",
  "..............",
];
picks.idle[3] = [  // Frame 4: big round bubble (3x3 with hollow center)
  ".........###..",
  "....####.#.#..",
  "..######.###..",
  ".#..........#.",
  ".#.###..###.#.",
  ".#..........#.",
  ".#....##....#.",
  ".#..........#.",
  "..##########..",
  "..##########..",
  "..............",
  "..............",
];

// TWEAK 2: Error — push the collapse further in frames 3-4
// Keep frames 1-2 from original, make 3-4 more dramatic
picks.error[2] = [  // Frame 3: major collapse, puddle forming
  "..............",
  "..............",
  "......##......",
  "...########...",
  "..##########..",
  ".#..##..##..#.",
  ".#..........#.",
  "..#...##...#..",
  "..##########..",
  ".###.####.###.",
  "####..##..####",
  "##.##.##.##.##",
];
picks.error[3] = [  // Frame 4: fully melted puddle, just eyes visible
  "..............",
  "..............",
  "..............",
  "..............",
  "......##......",
  "...########...",
  "..#.##..##.#..",
  "..#...##...#..",
  ".##########.#.",
  "##############",
  "####.####.####",
  "##############",
];

// TWEAK 3: Input — point right, hand extended right, eyes center↔right
picks.input = [
  [  // Frame 1: eyes center, right arm extended pointing right
    "......##......",
    "....######....",
    "..##########..",
    ".#..........#.",
    ".#..##..##..#.",
    ".#..........#.",
    ".#....##....#.",
    ".#..........#.",
    "..##########..",
    "....######..##",
    "...#......####",
    "..##..........",
  ],
  [  // Frame 2: eyes shift right, arm still pointing
    "......##......",
    "....######....",
    "..##########..",
    ".#..........#.",
    ".#....##..##.#",
    ".#..........#.",
    ".#....##....#.",
    ".#..........#.",
    "..##########..",
    "....######..##",
    "...#......####",
    "..##..........",
  ],
  [  // Frame 3: eyes center again, arm extends further
    "......##......",
    "....######....",
    "..##########..",
    ".#..........#.",
    ".#..##..##..#.",
    ".#..........#.",
    ".#....##....#.",
    ".#..........#.",
    "..##########..",
    "....######.###",
    "...#......####",
    "..##..........",
  ],
  [  // Frame 4: eyes right again
    "......##......",
    "....######....",
    "..##########..",
    ".#..........#.",
    ".#....##..##.#",
    ".#..........#.",
    ".#....##....#.",
    ".#..........#.",
    "..##########..",
    "....######..##",
    "...#......####",
    "..##..........",
  ],
];

// Speaking — mouth + waves out (user confirmed)
picks.speaking = [
  ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
  ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."],
  ["......##......","....######....","..##########.#",".#..........#.",".#..##..##..#.",".#..........#.",".#.########.#.",".#.#......#.#.","..##########..","....######....","...#......#...","..##......##.."],
  ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."],
];

// Listening — 5 new attempts
const listeningAlts = {
  "A: Antenna vibrate": {
    frames: [
      ["....##........","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["........##....","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      [".....##.......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      [".......##.....","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
    ]
  },
  "B: Sound waves in": {
    frames: [
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","#.##########.#",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.","##..##..##..##",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.","##..........##","..##########..","....######....","...#......#...","..##......##.."],
    ]
  },
  "C: Recording dot blink": {
    frames: [
      [".....####.....","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      [".....####.....","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#....##....#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
    ]
  },
  "D: Cupped ear lean": {
    frames: [
      [".......##.....","....######....","..##########..","..#..........#","..#..##..##..#","..#..........#","..#....##....#","..#..........#","...##########.",".....######...","....#......#..","...##......##."],
      [".......##.....","....######....","..##########..","..#..........#","..#..##..##..#","..#..........#","..#....##....#","..#..........#","...##########.",".....######...","####.......#..","....#......##."],
      [".......##.....","....######....","..##########..","..#..........#","..#..##..##..#","..#..........#","..#....##....#","..#..........#","...##########.",".....######...","....#......#..","...##......##."],
      [".......##.....","....######....","..##########..","..#..........#","..#..##..##..#","..#..........#","..#....##....#","..#..........#","...##########.",".....######...","####.......#..","....#......##."],
    ]
  },
  "E: Mouth open + still": {
    frames: [
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..#....#..#.","..##########..","....######....","...#......#...","..##......##.."],
      ["......##......","....######....","..##########..",".#..........#.",".#..##..##..#.",".#..........#.",".#..######..#.",".#..........#.","..##########..","....######....","...#......#...","..##......##.."],
    ]
  },
};

const allSprites = {...picks};
Object.entries(listeningAlts).forEach(([k, v]) => {
  allSprites["l_" + k.replace(/[^a-zA-Z0-9]/g, "")] = v.frames;
});

function card(id, title, sub, desc) {
  return `<div class="card"><h3>${desc || title}</h3><div class="sub">${sub}</div>
    <div class="lcd"><canvas id="c${id}"></canvas><div class="lt"><div class="t">${title}</div><div class="d">${sub}</div></div></div>
    <div class="fi" id="f${id}">Frame 1/4</div>
    <div class="ctrls"><button onclick="pv('${id}')"> &lt; </button>
    <button class="on" id="p${id}" onclick="tg('${id}')">Playing</button>
    <button onclick="nx('${id}')"> &gt; </button></div></div>`;
}

let body = '<h2 class="section">Tweaked Picks (from 60-set, minimal changes)</h2><div class="row">';
body += card("idle", "Snoozing", "Gone fishing · 5m", "Bigger bubbles (frames 3-4)");
body += card("error", "Error", "Oof · rate limited", "More collapse (frames 3-4)");
body += card("input", "Needs input", "Hey · Check terminal", "Points right, eyes center↔right");
body += '</div><div class="row">';
body += card("working", "Working...", "Tinkering · Bash", "Unchanged from 60-set");
body += card("done", "Done!", "Your turn", "Unchanged from 60-set");
body += card("approve", "Allow?", "Knocking · Bash", "Unchanged from 60-set");
body += '</div>';

body += '<h2 class="section">Speaking (confirmed)</h2><div class="row">';
body += card("speaking", "Speaking...", "Here's what I did...", "Mouth + waves out");
body += '</div>';

body += '<h2 class="section">Listening (5 new alts)</h2><div class="row">';
Object.entries(listeningAlts).forEach(([k, v]) => {
  const id = "l_" + k.replace(/[^a-zA-Z0-9]/g, "");
  body += card(id, "Listening...", "Go ahead · 3s", k.split(": ")[1]);
});
body += '</div>';

const output = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>CC-Beeper — Tweaked Picks</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#1a1a1a;color:#c8d6a0;font-family:monospace;padding:20px}
h1{color:#c8d6a0;margin-bottom:8px;font-size:18px}h2.section{color:#fff;font-size:16px;margin:32px 0 6px;padding-bottom:6px;border-bottom:1px solid #333}h2.section:first-of-type{margin-top:16px}
p.ctx{color:#777;font-size:11px;margin-bottom:16px}.row{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;max-width:960px;margin-bottom:32px}
.card{background:#2a2a2a;border-radius:12px;padding:14px;border:2px solid #3a3a3a}.card h3{font-size:13px;margin-bottom:3px;color:#fff}
.card .sub{font-size:10px;color:#888;margin-bottom:10px;line-height:1.5}
.lcd{background:#b8c878;border-radius:8px;padding:10px;display:flex;align-items:center;gap:8px;min-height:70px}
canvas{image-rendering:pixelated;flex-shrink:0}.lt{flex:1}.lt .t{font-size:13px;font-weight:900;color:#4a5a28}.lt .d{font-size:8px;color:#4a5a28;opacity:.7;margin-top:2px}
.fi{font-size:9px;color:#555;margin-top:6px;text-align:center}.ctrls{margin-top:6px;display:flex;gap:6px;justify-content:center}
.ctrls button{background:#3a3a3a;border:1px solid #555;color:#ccc;padding:3px 8px;border-radius:4px;cursor:pointer;font-size:10px}
.ctrls button:hover{background:#4a4a4a}.ctrls button.on{background:#5a7a2a;border-color:#7a9a3a}</style></head><body>
<h1>CC-Beeper — Tweaked Picks + Listening Alts</h1>${body}
<script>var PX=3,ON="#4a5a28";var sprites=${JSON.stringify(allSprites)};var st={};
Object.keys(sprites).forEach(function(k){st[k]={f:0,p:true};var c=document.getElementById("c"+k);if(c)draw(c,sprites[k][0])});
function draw(c,rows){var x=c.getContext("2d"),cols=rows[0].length;c.width=cols*PX;c.height=rows.length*PX;x.clearRect(0,0,c.width,c.height);x.fillStyle=ON;rows.forEach(function(row,r){for(var i=0;i<row.length;i++){if(row[i]==="#")x.fillRect(i*PX,r*PX,PX,PX)}})}
function upd(k){var s=st[k];var c=document.getElementById("c"+k);if(c)draw(c,sprites[k][s.f]);var f=document.getElementById("f"+k);if(f)f.textContent="Frame "+(s.f+1)+"/"+sprites[k].length}
function nx(k){var s=st[k];s.f=(s.f+1)%sprites[k].length;upd(k)}
function pv(k){var s=st[k];s.f=(s.f-1+sprites[k].length)%sprites[k].length;upd(k)}
function tg(k){var s=st[k];s.p=!s.p;var b=document.getElementById("p"+k);if(b){b.textContent=s.p?"Playing":"Paused";b.className=s.p?"on":""}}
setInterval(function(){Object.keys(st).forEach(function(k){if(st[k].p)nx(k)})},450);
</script></body></html>`;

fs.writeFileSync("voice-alts.html", output);
console.log("Done");
