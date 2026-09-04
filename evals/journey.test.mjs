import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { Script, runInNewContext } from "node:vm";

const html = readFileSync(new URL("../index.html", import.meta.url), "utf8");

function functionSource(name) {
  const start = html.indexOf("function " + name + "(");
  assert.ok(start >= 0, name);
  let candidate = "";
  for (const line of html.slice(start).split("\n")) {
    candidate += line + "\n";
    try {
      new Script("(" + candidate + ")");
      return candidate;
    } catch {}
  }
  throw new Error("Could not extract function: " + name);
}

test("inline scripts parse", () => {
  for (const [, source] of html.matchAll(/<script>([\s\S]*?)<\/script>/g)) new Script(source);
});

function copyAction(clipboard) {
  const control = {};
  const messages = [];
  const source = html.slice(html.indexOf('$("#rcopy").onclick='), html.indexOf('$("#rwa").onclick='));
  runInNewContext(source, { $: () => control, rotTxt: () => "roteiro completo", navigator: { clipboard },
    alert: (text) => messages.push(text), window: { prompt: (text, body) => messages.push({ text, body }) } });
  return { control, messages };
}

test("copy confirms only after the clipboard succeeds", async () => {
  let copied;
  const { control, messages } = copyAction({ writeText: async (text) => { copied = text; } });
  await control.onclick();
  assert.equal(copied, "roteiro completo");
  assert.match(messages[0], /Roteiro copiado/);
});

test("clipboard denial offers manual copy without a success claim", async () => {
  const { control, messages } = copyAction({ writeText: async () => { throw new Error("denied"); } });
  await control.onclick();
  assert.equal(messages[0].body, "roteiro completo");
  assert.match(messages[0].text, /Não foi possível/);
});

test("removed favorites cannot remain in exported ceremony text", () => {
  const context = { MOM: ["Entrada"], favs: {}, localStorage: { getItem: () => '{"Entrada":"t1"}' }, byId: () => ({ t: "Antiga", a: "Autor", yt: "id" }) };
  const output = runInNewContext(functionSource("rotTxt") + "\nrotTxt()", context);
  assert.match(output, /a escolher/);
  assert.ok(!output.includes("Antiga"));
});
