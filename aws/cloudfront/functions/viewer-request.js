/**
 * CloudFront viewer-request function for scriptchess.com (prod and dev share this file).
 *
 * 1. www.<host>             -> 301 to <host>, same path and query string
 * 2. legacy routes          -> 301 to the new route, query string kept
 * 3. client-rendered routes -> served the app shell (/index.csr.html)
 * 4. everything else        -> passed to S3 untouched (prerendered file, or the 404 error page)
 *
 * Query strings are never needed at the origin (the app reads them in the browser), so the cache
 * policy ignores them. They only have to survive the redirects above, which is what toQuery() does.
 */

// BEGIN client-only routes: copy from `npm run cloudfront:allowlist` in scriptchess-fe
var CLIENT_ONLY = [
  new RegExp("^/dev/components/?$"),
  new RegExp("^/engine-lab/?$"),
  new RegExp("^/insight/[^/]+/?$"),
  new RegExp("^/study/endgame-trainer/[^/]+/[^/]+/scenarios/[^/]+/?$"),
  new RegExp("^/study/endgame-trainer/[^/]+/drills/?$")
];
// END client-only routes

var STATIC_REDIRECTS = {
  "/free-chess-explorer": "/study/free-chess-explorer",
  "/tools/free-chess-explorer": "/study/free-chess-explorer",
  "/tools/play-against-chess-bots": "/study/play-against-chess-bots",
  "/tools/openings": "/study/openings",
  "/tools/chess-puzzles": "/study/solve-puzzles",
  "/tools/solve-chess-puzzles-and-chess-positions": "/study/solve-puzzles",
  "/tools/study": "/study",
  "/tools/endgame-trainer": "/study/endgame-trainer",
  "/tools/training": "/study/training",
  "/tools/download-games": "/tools/pgn-downloader",
  "/tools/novelty-finder": "/tools/position-explainer",
  "/tools/puzzle-sets": "/study/collections",
  "/tools/position-quiz": "/study/solve-puzzles",
  "/search/tournaments": "/study/tournaments",
  "/search/games": "/study/search-games",
  "/search/players": "/study/search-games",
  "/pages/how-to-play-chess": "/beginners/how-to-play-chess",
  "/pages/understanding-chess-notations-a-complete-biginner-s-guide": "/beginners/understanding-chess-notations-a-complete-biginner-s-guide",
  "/pages/know-chess-jargons": "/beginners/know-chess-jargons",
  "/pages/how-to-use-scriptchess": "/beginners/how-to-use-scriptchess",
  "/pages/how-to-start-a-professional-chess-career": "/beginners/how-to-start-a-professional-chess-career",
  "/pages/about-script-chess": "/about",
  "/pages/about-scripchess": "/about",
  "/pages/contact-us": "/about"
};

// Pattern routes, checked in order. `to` receives the regex match.
var DYNAMIC_REDIRECTS = [
  // /search/collections/:category
  { re: /^\/search\/collections\/([^\/]+)$/, to: function (m) { return "/study/collections/" + m[1]; } },
  // /search/collections/:collectionId/:collectionName
  { re: /^\/search\/collections\/([^\/]+)\/([^\/]+)$/, to: function (m) { return "/study/collections/all/" + m[2] + "/" + m[1]; } },
  // /tools/openings/:eco/:slug/:id
  { re: /^\/tools\/openings\/([^\/]+)\/([^\/]+)\/([^\/]+)$/, to: function (m) { return "/study/openings/" + m[2] + "/" + m[3]; } },
  // /search/tournaments/:tournamentId/:tournamentName/:year
  { re: /^\/search\/tournaments\/([^\/]+)\/([^\/]+)\/([^\/]+)$/, to: function (m) { return "/study/tournaments/" + m[2] + "/" + m[3] + "/" + m[1]; } }
];

function legacyTarget(uri) {
  if (Object.prototype.hasOwnProperty.call(STATIC_REDIRECTS, uri)) return STATIC_REDIRECTS[uri];
  for (var i = 0; i < DYNAMIC_REDIRECTS.length; i++) {
    var m = DYNAMIC_REDIRECTS[i].re.exec(uri);
    if (m) return DYNAMIC_REDIRECTS[i].to(m);
  }
  return null;
}

// Values may arrive decoded or still encoded: decode first so nothing is encoded twice.
function enc(value) {
  var decoded = value;
  try { decoded = decodeURIComponent(value); } catch (e) { /* keep as is */ }
  return encodeURIComponent(decoded);
}

/** "?a=1&b=2" from CloudFront's querystring object, or "" when there is none. Repeated keys are kept. */
function toQuery(querystring) {
  var parts = [];
  for (var key in querystring) {
    if (!Object.prototype.hasOwnProperty.call(querystring, key)) continue;
    var entry = querystring[key];
    var values = entry.multiValue && entry.multiValue.length ? entry.multiValue.map(function (v) { return v.value; }) : [entry.value];
    for (var i = 0; i < values.length; i++) {
      parts.push(values[i] === "" || values[i] === undefined ? enc(key) : enc(key) + "=" + enc(values[i]));
    }
  }
  return parts.length ? "?" + parts.join("&") : "";
}

function redirect(location) {
  return {
    statusCode: 301,
    statusDescription: "Moved Permanently",
    headers: { location: { value: location } }
  };
}

function handler(event) {
  var request = event.request;
  var uri = request.uri;
  var host = request.headers.host ? request.headers.host.value : "";
  var query = toQuery(request.querystring);

  var target = legacyTarget(uri);
  var path = target || uri;

  if (host.indexOf("www.") === 0) {
    return redirect("https://" + host.substring(4) + path + query);
  }
  if (target) {
    return redirect(target + query);
  }

  for (var i = 0; i < CLIENT_ONLY.length; i++) {
    if (CLIENT_ONLY[i].test(uri)) {
      request.uri = "/index.csr.html";
      break;
    }
  }
  return request;
}

if (typeof module !== "undefined") module.exports = { handler: handler, toQuery: toQuery };
