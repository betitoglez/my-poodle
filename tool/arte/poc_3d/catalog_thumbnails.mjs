/** Capture the catalogue cards using the bundled WebGL viewer and GLB.
 * Run with Node.js 22 and Chrome installed. Set CHROME_PATH on other platforms.
 */
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { setTimeout as delay } from 'node:timers/promises';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const assets = join(root, 'assets/wardrobe_live');
const output = join(root, 'assets/images/wardrobe_thumbs');
const { styles } = JSON.parse(await readFile(join(root, 'assets/data/balance-v1.json'), 'utf8'));
const cutStyles = ['natural','teddy','pom','puppy','show','modern'];
styles.push(...['head','legs','back','tail'].flatMap(zone => cutStyles.map(style => ({id: `cut.${zone}.${style}`, slot: zone === 'head' ? 'head' : zone === 'legs' ? 'paws' : 'hair'}))));
const requested = new Set(process.argv.slice(2));
const bridge = '<script>window.PoodleHost = { ready() { window.viewerReady = true; }, failed() { window.viewerFailed = true; } };</script>';
const html = await readFile(join(assets, 'index.html'), 'utf8');
const contentTypes = { js: 'text/javascript', glb: 'model/gltf-binary' };
const server = createServer(async (request, response) => {
  const path = request.url.slice(1);
  if (!path) {
    response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    response.end(html.replace('<script type="module"', bridge + '<script type="module"'));
    return;
  }
  const type = contentTypes[path.split('.').at(-1)];
  if (!type || !/^[a-zA-Z0-9./_-]+$/.test(path) || path.includes('..')) {
    response.writeHead(404).end();
    return;
  }
  try {
    const data = await readFile(join(assets, path));
    response.writeHead(200, { 'Content-Type': type }).end(data);
  } catch {
    response.writeHead(404).end();
  }
});

function connect(socket) {
  let id = 0;
  const waiting = new Map();
  socket.addEventListener('message', ({ data }) => {
    const message = JSON.parse(data);
    const call = waiting.get(message.id);
    if (!call) return;
    waiting.delete(message.id);
    if (message.error) call.reject(new Error(message.error.message));
    else call.resolve(message.result);
  });
  return (method, params = {}) => new Promise((resolve, reject) => {
    waiting.set(++id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

const frames = {
  body: { y: 0.94, size: 0.78, angle: -23 },
  head: { y: 1.96, size: 1.71, angle: -9 },
  neck: { y: 1.68, size: 1.85, angle: -7 },
  paws: { y: 0.87, size: 2.04, angle: -29 },
};
const frameFor = {
  head: 'head', eyes: 'head', neck: 'neck', collar: 'neck', paws: 'paws',
};
await mkdir(output, { recursive: true });
const profile = await mkdtemp(join(tmpdir(), 'mypoodle-thumbs-'));
let chrome;
let socket;
try {
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const executable = process.env.CHROME_PATH ??
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  chrome = spawn(executable, [
    '--headless', '--no-first-run', '--disable-background-networking',
    '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
    '--remote-debugging-port=0', '--user-data-dir=' + profile, 'about:blank',
  ], { stdio: 'ignore' });
  let chromeError;
  chrome.on('error', error => { chromeError = error; });
  let debuggerPort;
  for (let attempt = 0; attempt < 100 && !debuggerPort; attempt++) {
    if (chromeError) throw chromeError;
    await delay(100);
    try {
      debuggerPort = (await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0];
    } catch {
      // Chrome creates this file once the local DevTools server is ready.
    }
  }
  if (!debuggerPort) throw new Error('Chrome did not start');
  const targets = await (await fetch('http://127.0.0.1:' + debuggerPort + '/json/list')).json();
  socket = new WebSocket(targets.find(target => target.type === 'page').webSocketDebuggerUrl);
  await once(socket, 'open');
  const call = connect(socket);
  const evaluate = async expression => {
    const result = await call('Runtime.evaluate', {
      expression, awaitPromise: true, returnByValue: true,
    });
    if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description ??
      result.exceptionDetails.text);
    return result.result.value;
  };
  await call('Emulation.setDeviceMetricsOverride', {
    width: 256, height: 224, deviceScaleFactor: 1, mobile: false,
  });
  await call('Emulation.setDefaultBackgroundColorOverride', {
    color: { r: 0, g: 0, b: 0, a: 0 },
  });
  const browserErrors = [];
  socket.addEventListener('message', ({data}) => {
    const message = JSON.parse(data);
    if (message.method === 'Runtime.consoleAPICalled' && message.params.type === 'error') browserErrors.push(message.params.args.map(a => a.value ?? a.description).join(' '));
    if (message.method === 'Runtime.exceptionThrown') browserErrors.push(message.params.exceptionDetails.text);
  });
  await call('Runtime.enable');
  await call('Page.navigate' , { url: 'http://127.0.0.1:' + server.address().port });
  await evaluate(`new Promise((resolve, reject) => {
    const until = performance.now() + 15000;
    const timer = setInterval(() => {
      if (!window.viewerReady && !window.viewerFailed && performance.now() < until) return;
      clearInterval(timer);
      if (window.viewerReady) resolve(true);
      else reject(new Error('The bundled viewer did not load'));
    }, 50);
  })`);

  let count = 0;
  for (const { id, slot } of styles) {
    if (requested.size && !requested.has(id)) continue;
    const { y, size, angle } = frames[frameFor[slot] ?? 'body'];
    const bits = id.split('.');
    const cut = bits[0] === 'cut';
    const cuts = cut ? ['head','legs','back','tail'].map(z => z === bits[1] ? cutStyles.indexOf(bits[2]) : 0) : Array(4).fill(slot === 'hair' ? cutStyles.indexOf(bits[1]) : 0);
    const configuration = {
      x: 0.5, y, size, cuts, reduced: true, resting: false,
      coat: slot === 'coat' ? id.split('.')[1] : 'apricot',
      pom: id === 'hair.pom', puppy: id === 'hair.puppy',
      teddy: id === 'hair.teddy', showCut: id === 'hair.show',
      wear: cut || slot === 'coat' || slot === 'hair' || id.endsWith('.none') ? [] : [id],
    };
    await evaluate(`(async () => {
      poodle.configure(${JSON.stringify(configuration)});
      poodle.front();
      poodle.rotate(${angle});
      await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    })()`);
    if (browserErrors.length) throw new Error(browserErrors.join('\n'));
    const { data } = await call('Page.captureScreenshot', { format: 'webp', quality: 93 });
    await writeFile(join(output, id + '.webp'), Buffer.from(data, 'base64'));
    count++;
  }
  console.log(`${count} catalogue thumbnails from the mobile viewer saved to ${output}`);
} finally {
  socket?.close();
  server.close();
  if (chrome?.pid && chrome.exitCode === null && chrome.signalCode === null) {
    const stopped = once(chrome, 'exit');
    chrome.kill();
    await stopped;
  }
  await rm(profile, { recursive: true, force: true });
}
