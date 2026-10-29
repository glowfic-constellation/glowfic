//= require hsluv
/* global gon, Hsluv */

// Drawing happens in SIZE x SIZE logical pixels, scaled up for high-DPI screens. The wheel itself is
// rendered at a lower resolution and smoothed, since every pixel is an HSLuv conversion.
const SIZE = 400;
const WHEEL_RESOLUTION = 320;
const DOT_RADIUS = 5.5;
const FADED_DOT_RADIUS = 3.5;
const HOVER_RADIUS = 9;
const NEAREST_COUNT = 8;

let canvas, context, wheelImage;
let moieties = [];
let lightness = 60;
let candidate = null;

$(document).ready(function() {
  canvas = document.getElementById('moiety-wheel');
  if (!canvas) return;
  const scale = window.devicePixelRatio || 1;
  canvas.width = SIZE * scale;
  canvas.height = SIZE * scale;
  context = canvas.getContext('2d');
  context.setTransform(scale, 0, 0, scale, 0, 0);
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
  styleSlider();
  renderWheel();
  draw();
}

function hsluvHex(hue, saturation, light) {
  const color = new Hsluv();
  color.hsluv_h = hue;
  color.hsluv_s = saturation;
  color.hsluv_l = light;
  color.hsluvToHex();
  return color.hex;
}

// The lightness track shows the picked color from black to white, and the thumb the color at this lightness
function styleSlider() {
  const hue = candidate ? candidate.color.hsluv_h : 0;
  const saturation = candidate ? candidate.color.hsluv_s : 0;
  const stops = [0, 20, 40, 60, 80, 100].map((light) => hsluvHex(hue, saturation, light) + ' ' + light + '%');
  const slider = document.getElementById('moiety_lightness');
  slider.style.background = 'linear-gradient(to right, ' + stops.join(', ') + ')';
  slider.style.setProperty('--moiety-thumb', hsluvHex(hue, saturation, lightness));
}

function renderWheel() {
  const ctx = wheelImage.getContext('2d');
  const image = ctx.createImageData(WHEEL_RESOLUTION, WHEEL_RESOLUTION);
  const color = new Hsluv();
  const center = WHEEL_RESOLUTION / 2;
  const radius = wheelRadius() * WHEEL_RESOLUTION / SIZE;
  for (let y = 0; y < WHEEL_RESOLUTION; y++) {
    for (let x = 0; x < WHEEL_RESOLUTION; x++) {
      const polar = toPolar(x + 0.5 - center, y + 0.5 - center, radius);
      if (polar.saturation > 101) continue;
      color.hsluv_h = polar.hue;
      color.hsluv_s = Math.min(polar.saturation, 100);
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
  return (SIZE / 2) - DOT_RADIUS - 2;
}

function toCanvas(hue, saturation) {
  const center = SIZE / 2;
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
  const center = SIZE / 2;
  context.clearRect(0, 0, SIZE, SIZE);
  context.save();
  context.beginPath();
  context.arc(center, center, wheelRadius(), 0, 2 * Math.PI);
  context.clip();
  context.imageSmoothingEnabled = true;
  context.imageSmoothingQuality = 'high';
  context.drawImage(wheelImage, 0, 0, SIZE, SIZE);
  context.restore();
  const ordered = moieties.slice().sort((a, b) => dotAlpha(a) - dotAlpha(b));
  ordered.forEach(drawDot);
  if (candidate) drawCandidate();
}

function drawDot(moiety) {
  const point = toCanvas(moiety.color.hsluv_h, moiety.color.hsluv_s);
  const alpha = dotAlpha(moiety);
  context.globalAlpha = alpha;
  context.beginPath();
  context.arc(point.x, point.y, alpha < 0.5 ? FADED_DOT_RADIUS : DOT_RADIUS, 0, 2 * Math.PI);
  context.fillStyle = moiety.hex;
  context.fill();
  context.lineWidth = 1;
  context.strokeStyle = moiety.color.hsluv_l > 60 ? 'rgba(0, 0, 0, 0.5)' : 'rgba(255, 255, 255, 0.8)';
  context.stroke();
  context.globalAlpha = 1;
}

function drawCandidate() {
  const point = toCanvas(candidate.color.hsluv_h, candidate.color.hsluv_s);
  context.beginPath();
  context.arc(point.x, point.y, DOT_RADIUS + 4, 0, 2 * Math.PI);
  context.lineWidth = 4;
  context.strokeStyle = 'rgba(0, 0, 0, 0.6)';
  context.stroke();
  context.lineWidth = 2;
  context.strokeStyle = '#fff';
  context.stroke();
}

function eventPoint(event) {
  const rect = canvas.getBoundingClientRect();
  const scale = SIZE / rect.width;
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
  const scale = canvas.getBoundingClientRect().width / SIZE;
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
  const center = SIZE / 2;
  const polar = toPolar(point.x - center, point.y - center, wheelRadius());
  if (polar.saturation > 105) return;
  const hex = hsluvHex(polar.hue, Math.min(polar.saturation, 100), lightness);
  $('#moiety_hex').val(hex.substring(1));
  setCandidate(hex);
  styleSlider();
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
  $('#moiety-swatch').css('background', hex);
  $('#moiety-sample-name').css('color', hex);
  $('#moiety-hsluv').text(`HSLuv ${Math.round(c.hsluv_h)}° ${Math.round(c.hsluv_s)}% ${Math.round(c.hsluv_l)}%`);
  showNearest();
}

// Euclidean distance in CIELUV, which HSLuv is built on
function colorDistance(a, b) {
  return Math.hypot(a.luv_l - b.luv_l, a.luv_u - b.luv_u, a.luv_v - b.luv_v);
}

function showNearest() {
  const nearest = moieties.map((moiety) => ({ moiety: moiety, distance: colorDistance(candidate.color, moiety.color) }));
  nearest.sort((a, b) => a.distance - b.distance);
  $('#moiety-nearest-list').empty().append(nearest.slice(0, NEAREST_COUNT).map(nearestItem));
  $('#moiety-nearest').toggleClass('hidden', nearest.length === 0);
}

function nearestItem(entry) {
  const moiety = entry.moiety;
  const meta = [moiety.moiety_name, moiety.hex].filter(Boolean).join(' · ');
  return $('<li>').append(
    $('<span>').addClass('dot').css('background', moiety.hex),
    $('<a>').addClass('name').attr('href', '/users/' + moiety.id).text(moiety.username).css('color', moiety.hex),
    $('<span>').addClass('meta').text(meta),
    $('<span>').addClass('distance').attr('title', 'Perceptual color difference (CIELUV ΔE): 0 is identical').text(entry.distance.toFixed(1))
  );
}
