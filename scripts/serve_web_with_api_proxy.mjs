#!/usr/bin/env node

import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer, request as httpRequest } from 'node:http';
import { request as httpsRequest } from 'node:https';
import { extname, join, normalize, resolve, sep } from 'node:path';

const host = process.env.HOST || '0.0.0.0';
const port = Number.parseInt(process.env.PORT || '8080', 10);
const backendOrigin = process.env.BACKEND_ORIGIN || 'https://apizhsp.zabtec.co';
const webRoot = resolve(process.env.WEB_ROOT || 'build/web');

const mimeTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

const shouldProxy = (pathname) =>
  pathname === '/health' ||
  pathname.startsWith('/api/v1/') ||
  pathname.startsWith('/uploads/');

const send = (res, statusCode, body, headers = {}) => {
  res.writeHead(statusCode, {
    'Cache-Control': 'no-store',
    ...headers,
  });
  res.end(body);
};

const proxyRequest = (req, res) => {
  const target = new URL(req.url, backendOrigin);
  const requestForProtocol = target.protocol === 'https:' ? httpsRequest : httpRequest;
  const upstreamHeaders = {
    ...req.headers,
    host: target.host,
  };
  delete upstreamHeaders.origin;

  const upstream = requestForProtocol(
    target,
    {
      method: req.method,
      headers: upstreamHeaders,
    },
    (upstreamRes) => {
      const headers = { ...upstreamRes.headers };
      delete headers['content-security-policy'];
      delete headers['cross-origin-opener-policy'];
      delete headers['cross-origin-resource-policy'];
      delete headers['strict-transport-security'];
      res.writeHead(upstreamRes.statusCode || 502, headers);
      upstreamRes.pipe(res);
    },
  );

  upstream.on('error', (error) => {
    send(
      res,
      502,
      JSON.stringify({
        success: false,
        message: `Backend proxy failed: ${error.message}`,
      }),
      { 'Content-Type': 'application/json; charset=utf-8' },
    );
  });

  req.pipe(upstream);
};

const staticPathFor = (pathname) => {
  const decoded = decodeURIComponent(pathname);
  const safePath = normalize(decoded).replace(/^(\.\.[/\\])+/, '');
  const filePath = resolve(join(webRoot, safePath));
  if (filePath !== webRoot && !filePath.startsWith(`${webRoot}${sep}`)) {
    return null;
  }
  if (existsSync(filePath) && statSync(filePath).isFile()) return filePath;
  return join(webRoot, 'index.html');
};

const serveStatic = (req, res, pathname) => {
  const filePath = staticPathFor(pathname);
  if (!filePath || !existsSync(filePath)) {
    send(res, 404, 'Not found', { 'Content-Type': 'text/plain; charset=utf-8' });
    return;
  }

  const ext = extname(filePath);
  res.writeHead(200, {
    'Content-Type': mimeTypes[ext] || 'application/octet-stream',
    'Cache-Control': 'no-store',
  });
  createReadStream(filePath).pipe(res);
};

const server = createServer((req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  if (shouldProxy(url.pathname)) {
    proxyRequest(req, res);
    return;
  }
  serveStatic(req, res, url.pathname);
});

server.listen(port, host, () => {
  console.log(`Serving ${webRoot} on http://${host}:${port}`);
  console.log(`Proxying API requests to ${backendOrigin}`);
});
