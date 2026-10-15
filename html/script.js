const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'forger-vehcontrol';
const post = (name, data) => fetch(`https://${RES}/${name}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json; charset=UTF-8' },
  body: JSON.stringify(data || {}),
}).catch(() => {});

const $ = (s) => document.querySelector(s);
const $$ = (s) => [...document.querySelectorAll(s)];
const dock = $('#dock');

const WIN_NAMES = ['Front Left', 'Front Right', 'Rear Left', 'Rear Right'];
const SEAT_NAMES = { '-1': 'Driver', '0': 'Passenger', '1': 'Rear Left', '2': 'Rear Right' };

$('#wins').innerHTML = WIN_NAMES.map((n, i) => `
  <button class="win" data-win="${i}">
    <svg viewBox="0 0 32 32"><path class="frame" d="M7 28V13l6-9h13v24z"/><rect class="glass" x="11" y="8" width="12" height="16" rx="1.5"/></svg>
    <span><b>${n}</b><small>Up</small></span>
  </button>`).join('');

const level = (el, v, warnAt, badAt) => {
  el.style.width = v + '%';
  el.classList.toggle('bad', v <= badAt);
  el.classList.toggle('warn', v > badAt && v <= warnAt);
};

function render(d) {
  $('#fuelV').textContent = d.fuel + '%';
  level($('#fuelB'), d.fuel, 30, 15);
  $('#hpV').textContent = d.health + '%';
  level($('#hpB'), d.health, 60, 30);

  const eng = $('#engine');
  eng.classList.toggle('on', d.engine);
  $('#engT').textContent = d.engine ? 'Engine on' : 'Engine off';
  $('#engS').textContent = d.isDriver ? (d.engine ? 'Tap to stop' : 'Tap to start') : 'Driver only';

  $$('[data-door]').forEach((el) => {
    const i = +el.dataset.door;
    el.classList.toggle('open', !!d.doors[i]);
    el.classList.toggle('disabled', !d.valid[i]);
  });

  $$('[data-win]').forEach((el) => {
    const i = +el.dataset.win;
    const down = !!d.windows[i];
    el.classList.toggle('down', down);
    el.classList.toggle('disabled', !d.valid[i]);
    el.querySelector('small').textContent = down ? 'Down' : 'Up';
    const g = el.querySelector('.glass');
    const h = down ? 3 : 16;
    g.setAttribute('height', h);
    g.setAttribute('y', 8 + (16 - h));
  });

  $('#seats').innerHTML = d.seats.map((s) => {
    const name = SEAT_NAMES[s.index] || `Seat ${s.index + 2}`;
    const cls = s.mine ? 'mine' : s.occupied ? 'occ' : '';
    return `<button class="chip ${cls}" data-seat="${s.index}"><svg><use href="#s-seat"/></svg>${name}</button>`;
  }).join('');
}

document.addEventListener('click', (e) => {
  const t = e.target.closest('[data-door],[data-win],[data-seat],#engine,#winAll,#close');
  if (!t) return;
  if (t.dataset.door !== undefined) post('door', { index: +t.dataset.door });
  else if (t.dataset.win !== undefined) post('window', { index: +t.dataset.win });
  else if (t.dataset.seat !== undefined) post('seat', { seat: +t.dataset.seat });
  else if (t.id === 'engine') post('engine');
  else if (t.id === 'winAll') post('windowsAll');
  else if (t.id === 'close') post('close');
});

window.addEventListener('keydown', (e) => { if (e.key === 'Escape') post('close'); });

window.addEventListener('message', (e) => {
  const m = e.data;
  if (m.action === 'open') { dock.classList.remove('hidden'); }
  else if (m.action === 'close') { dock.classList.add('hidden'); }
  else if (m.action === 'update') render(m.data);
});
