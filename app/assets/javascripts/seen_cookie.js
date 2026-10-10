// A cookie the server never sets, so pages stay shareable but returning readers still send one.
(function() {
  if (document.cookie.split('; ').some((cookie) => cookie.startsWith('glowfic_seen='))) { return; }
  const secure = window.location.protocol === 'https:' ? '; Secure' : '';
  document.cookie = `glowfic_seen=1; Max-Age=31536000; Path=/; SameSite=Lax${secure}`;
}());
