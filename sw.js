const CACHE = 'juku-20260707b';
const HTML_URLS = ['/', '/index.html'];
const STATIC_URLS = ['/manifest.json', '/icon.svg'];

// install: プレキャッシュ → すぐ有効化
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll([...HTML_URLS, ...STATIC_URLS]))
      .then(() => self.skipWaiting())
  );
});

// activate: 古いキャッシュを削除 → すべてのクライアントを即時制御
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// fetch: HTML はネットワークファースト、それ以外はキャッシュファースト
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  const isHtml = HTML_URLS.includes(url.pathname) || url.pathname === '/';

  if (isHtml) {
    // ネットワークファースト: 成功したらキャッシュを更新
    e.respondWith(
      fetch(e.request)
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
          return res;
        })
        .catch(() => caches.match(e.request))
    );
  } else {
    // キャッシュファースト
    e.respondWith(
      caches.match(e.request).then(r => r || fetch(e.request).then(res => {
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
        return res;
      }))
    );
  }
});

// メッセージ受信: SKIP_WAITING を受け取ったら即時有効化
self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});
