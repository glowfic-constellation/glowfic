//= require hsluv
/* global gon, Hsluv */

// The wheel is rendered at a lower resolution and scaled up, since every pixel is an HSLuv conversion
const WHEEL_RESOLUTION = 200;
const DOT_RADIUS = 6;
const HOVER_RADIUS = 9;
const NEAREST_COUNT = 10;

let canvas, context, wheelImage;
let moieties = [];
let lightness = 60;
let candidate = null;

$(document).ready(function() {
  canvas = document.getElementById('moiety-wheel');
  if (!canvas) return;
  context = canvas.getContext('2d');
  wheelImage = document.createElement('canvas');
  wheelImage.width = WHEEL_RESOLUTION;
  wheelImage.height = WHEEL_RESOLUTION;
  moieties = gon.moieties.map(parseMoiety).filter(Boolean);

  $('#moiety_lightness').on('input', function() { setLightness(parseInt(this.value, 10)); });
  // Wait for a full six digits while typing; a three-digit code counts once the field is left
  $('#moiety_hex').on('input', function() { if (this.value.replace('#', '').length === 6) pickHex(this.value); });
  $('#moiety_hex').on('change', function() { pickHex(this.value); });
  $(canvas).on('mousemove', showHover).on('mouseleave', hideHover).on('click', pickFromWheel);

  const initialHex = new URLSearchParams(window.location.search).get('hex');
  if (initialHex) {
    $('#moiety_hex').val(initialHex.replace('#', ''));
    pickHex(initialHex);
  } else {
    setLightness(lightness);
  }
});

function normalizeHex(hex) {
  hex = String(hex || '').replace('#', '').toLowerCase();
  if (/^[0-9a-f]{3}$/.test(hex)) hex = hex.split('').map((c) => c + c).join('');
  if (!/^[0-9a-f]{6}$/.test(hex)) return null;
  return '#' + hex;
}

function colorFromHex(hex) {
  const color = new Hsluv();
  color.hex = hex;
  color.hexToHsluv();
  return color;
}

function parseMoiety(moiety) {
  const hex = normalizeHex(moiety.moiety);
  if (!hex) return null;
  return Object.assign({}, moiety, { hex: hex, color: colorFromHex(hex) });
}

function setLightness(value) {
  lightness = value;
  $('#moiety_lightness').val(value);
  $('#moiety-lightness-value').text(value);
  renderWheel();
  draw();
}

function renderWheel() {
  const ctx = wheelImage.getContext('2d');
  const image = ctx.createImageData(WHEEL_RESOLUTION, WHEEL_RESOLUTION);
  const color = new Hsluv();
  const center = WHEEL_RESOLUTION / 2;
  const radius = wheelRadius() * WHEEL_RESOLUTION / canvas.width;
  for (let y = 0; y < WHEEL_RESOLUTION; y++) {
    for (let x = 0; x < WHEEL_RESOLUTION; x++) {
      const polar = toPolar(x + 0.5 - center, y + 0.5 - center, radius);
      if (polar.saturation > 100) continue;
      color.hsluv_h = polar.hue;
      color.hsluv_s = polar.saturation;
      color.hsluv_l = lightness;
      color.hsluvToRgb();
      const i = ((y * WHEEL_RESOLUTION) + x) * 4;
      image.data[i] = Math.round(color.rgb_r * 255);
      image.data[i + 1] = Math.round(color.rgb_g * 255);
      image.data[i + 2] = Math.round(color.rgb_b * 255);
      image.data[i + 3] = 255;
    }
  }
  ctx.putImageData(image, 0, 0);
}

// Hue increases counterclockwise from the right, saturation outward from the center
function toPolar(dx, dy, radius) {
  const hue = ((Math.atan2(-dy, dx) * 180 / Math.PI) + 360) % 360;
  return { hue: hue, saturation: Math.hypot(dx, dy) / radius * 100 };
}

// Leaves room for dots at full saturation to fit inside the canvas
function wheelRadius() {
  return (canvas.width / 2) - DOT_RADIUS;
}

function toCanvas(hue, saturation) {
  const center = canvas.width / 2;
  const angle = hue * Math.PI / 180;
  const distance = Math.min(saturation, 100) / 100 * wheelRadius();
  return { x: center + (distance * Math.cos(angle)), y: center - (distance * Math.sin(angle)) };
}

// Moieties far from the wheel's lightness fade out, so the dots that look like the wheel under them stand out
function dotAlpha(moiety) {
  const distance = Math.abs(moiety.color.hsluv_l - lightness);
  return Math.max(0.15, 1 - (Math.max(distance - 10, 0) / 30));
}

function draw() {
  context.clearRect(0, 0, canvas.width, canvas.height);
  context.imageSmoothingEnabled = true;
  context.drawImage(wheelImage, 0, 0, canvas.width, canvas.height);
  const ordered = moieties.slice().sort((a, b) => dotAlpha(a) - dotAlpha(b));
  ordered.forEach(drawDot);
  if (candidate) drawCandidate();
}

function drawDot(moiety) {
  const point = toCanvas(moiety.color.hsluv_h, moiety.color.hsluv_s);
  context.globalAlpha = dotAlpha(moiety);
  context.beginPath();
  context.arc(point.x, point.y, DOT_RADIUS, 0, 2 * Math.PI);
  context.fillStyle = moiety.hex;
  context.fill();
  context.lineWidth = 1.5;
  context.strokeStyle = moiety.color.hsluv_l > 50 ? '#000' : '#fff';
  context.stroke();
  context.globalAlpha = 1;
}

function drawCandidate() {
  const point = toCanvas(candidate.color.hsluv_h, candidate.color.hsluv_s);
  context.beginPath();
  context.arc(point.x, point.y, DOT_RADIUS + 4, 0, 2 * Math.PI);
  context.lineWidth = 3;
  context.strokeStyle = '#fff';
  context.stroke();
  context.lineWidth = 1.5;
  context.strokeStyle = '#000';
  context.stroke();
}

function eventPoint(event) {
  const rect = canvas.getBoundingClientRect();
  const scale = canvas.width / rect.width;
  return { x: (event.clientX - rect.left) * scale, y: (event.clientY - rect.top) * scale };
}

// The most visible dot under the pointer, if any
function dotAt(point) {
  let best = null;
  moieties.forEach(function(moiety) {
    const dot = toCanvas(moiety.color.hsluv_h, moiety.color.hsluv_s);
    if (Math.hypot(dot.x - point.x, dot.y - point.y) > HOVER_RADIUS) return;
    if (!best || dotAlpha(moiety) > dotAlpha(best)) best = moiety;
  });
  return best;
}

function showHover(event) {
  const point = eventPoint(event);
  const moiety = dotAt(point);
  if (!moiety) {
    hideHover();
    return;
  }
  const scale = canvas.getBoundingClientRect().width / canvas.width;
  const label = moiety.username + (moiety.moiety_name ? ` (${moiety.moiety_name})` : '') + ' ' + moiety.hex;
  $('#moiety-hover').text(label).css({ left: (point.x * scale) + 12, top: (point.y * scale) + 12 }).show();
}

function hideHover() {
  $('#moiety-hover').hide();
}

function pickFromWheel(event) {
  const point = eventPoint(event);
  const moiety = dotAt(point);
  if (moiety) {
    pickHex(moiety.hex);
    $('#moiety_hex').val(moiety.hex.substring(1));
    return;
  }
  const center = canvas.width / 2;
  const polar = toPolar(point.x - center, point.y - center, wheelRadius());
  if (polar.saturation > 105) return;
  const color = new Hsluv();
  color.hsluv_h = polar.hue;
  color.hsluv_s = Math.min(polar.saturation, 100);
  color.hsluv_l = lightness;
  color.hsluvToHex();
  $('#moiety_hex').val(color.hex.substring(1));
  setCandidate(color.hex);
  draw();
}

// A typed or clicked-on existing color also moves the wheel to that color's lightness
function pickHex(value) {
  const hex = normalizeHex(value);
  if (!hex) return;
  setCandidate(hex);
  setLightness(Math.round(candidate.color.hsluv_l));
}

function setCandidate(hex) {
  candidate = { hex: hex, color: colorFromHex(hex) };
  const c = candidate.color;
  $('#moiety-swatch').text('█').css('color', hex);
  $('#moiety-sample-name').css('color', hex);
  $('#moiety-hsluv').text(`${hex}: HSLuv ${Math.round(c.hsluv_h)}°, ${Math.round(c.hsluv_s)}%, ${Math.round(c.hsluv_l)}%`);
  $('#moiety-sample').removeClass('hidden');
  showNearest();
}

// Euclidean distance in CIELUV, which HSLuv is built on
function colorDistance(a, b) {
  return Math.hypot(a.luv_l - b.luv_l, a.luv_u - b.luv_u, a.luv_v - b.luv_v);
}

function showNearest() {
  const nearest = moieties.map((moiety) => ({ moiety: moiety, distance: colorDistance(candidate.color, moiety.color) }));
  nearest.sort((a, b) => a.distance - b.distance);
  const body = $('#moiety-nearest tbody').empty();
  nearest.slice(0, NEAREST_COUNT).forEach(function(entry, index) {
    body.append(nearestRow(entry, index % 2 ? 'odd' : 'even'));
  });
  $('#moiety-nearest').toggleClass('hidden', nearest.length === 0);
}

function nearestRow(entry, klass) {
  const moiety = entry.moiety;
  const row = $('<tr>');
  const swatch = $('<span>').text('█').css('color', moiety.hex).attr('title', moiety.moiety_name || '');
  const link = $('<a>').attr('href', '/users/' + moiety.id).text(moiety.username).css({ color: moiety.hex, fontWeight: 'bold' });
  row.append($('<td>').addClass(klass + ' padding-5 centered').append(swatch));
  row.append($('<td>').addClass(klass + ' padding-5').append(link, moiety.moiety_name ? $('<span>').text(' ' + moiety.moiety_name) : null));
  row.append($('<td>').addClass(klass + ' padding-5').text(moiety.hex));
  row.append($('<td>').addClass(klass + ' padding-5').text(entry.distance.toFixed(1)));
  return row;
}
