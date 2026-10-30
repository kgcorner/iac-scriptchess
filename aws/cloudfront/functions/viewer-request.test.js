// Run: node --test aws/cloudfront/functions/viewer-request.test.js
const test = require("node:test");
const assert = require("node:assert");
const { handler, toQuery } = require("./viewer-request.js");

const ev = (uri, host = "scriptchess.com", querystring = {}) => ({ request: { uri, headers: { host: { value: host } }, querystring } });
const q = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, { value: v }]));

test("www goes to the bare host and keeps path and query", () => {
  const r = handler(ev("/tools/free-chess-engine", "www.scriptchess.com", q({ gameId: "42", utm_source: "x" })));
  assert.strictEqual(r.statusCode, 301);
  assert.strictEqual(r.headers.location.value, "https://scriptchess.com/tools/free-chess-engine?gameId=42&utm_source=x");
});

test("www plus a legacy route is one redirect, not two", () => {
  const r = handler(ev("/pages/contact-us", "www.scriptchess.com", q({ a: "1" })));
  assert.strictEqual(r.headers.location.value, "https://scriptchess.com/about?a=1");
});

test("legacy static route keeps the query string", () => {
  const r = handler(ev("/tools/openings", "scriptchess.com", q({ q: "sicilian defence" })));
  assert.strictEqual(r.headers.location.value, "/study/openings?q=sicilian%20defence");
});

test("legacy dynamic routes", () => {
  assert.strictEqual(handler(ev("/search/collections/endgames")).headers.location.value, "/study/collections/endgames");
  assert.strictEqual(handler(ev("/search/collections/7/rook-endings")).headers.location.value, "/study/collections/all/rook-endings/7");
  assert.strictEqual(handler(ev("/tools/openings/B20/sicilian/55")).headers.location.value, "/study/openings/sicilian/55");
  assert.strictEqual(handler(ev("/search/tournaments/9/olympiad/2024")).headers.location.value, "/study/tournaments/olympiad/2024/9");
});

test("client-only routes get the app shell, query untouched", () => {
  const e = ev("/insight/job-abc", "scriptchess.com", q({ a: "1" }));
  const r = handler(e);
  assert.strictEqual(r.uri, "/index.csr.html");
  assert.deepStrictEqual(r.querystring, { a: { value: "1" } });
});

test("other routes pass through unchanged", () => {
  const r = handler(ev("/study/openings"));
  assert.strictEqual(r.uri, "/study/openings");
});

test("a path like /constructor or __proto__ is not mistaken for a legacy route", () => {
  assert.strictEqual(handler(ev("/constructor")).uri, "/constructor");
  assert.strictEqual(handler(ev("/__proto__")).uri, "/__proto__");
});

test("query encoding: repeated keys, bare keys, already-encoded values", () => {
  assert.strictEqual(toQuery({}), "");
  assert.strictEqual(toQuery({ a: { value: "1", multiValue: [{ value: "1" }, { value: "2" }] } }), "?a=1&a=2");
  assert.strictEqual(toQuery({ flag: { value: "" } }), "?flag");
  assert.strictEqual(toQuery({ fen: { value: "rnbq%2Fpp" } }), "?fen=rnbq%2Fpp");
  assert.strictEqual(toQuery({ fen: { value: "rnbq/pp" } }), "?fen=rnbq%2Fpp");
});
