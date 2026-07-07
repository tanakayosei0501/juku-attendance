const CACHE = 'juku-static-v1';
const STATIC_ASSETS = ['/manifest.json', '/icon.svg'];

// install: 静的アセットのみプリキャッシュ → 即時有効化
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// activate: 古いキャッシュを全削除 → 全クライアントを即時制御
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // 同一オリジンの GET リクエストのみ処理
  if (e.request.method !== 'GET' || url.origin !== self.location.origin) return;

  const isHtml   = url.pathname === '/' || url.pathname.endsWith('.html');
  const isStatic = STATIC_ASSETS.includes(url.pathname);

  if (isHtml) {
    // HTML: 常にネットワークから取得（HTTP キャッシュも無視）
    // ネット不通のときだけ SW キャッシュにフォールバック
    e.respondWith(
      fetch(e.request, { cache: 'no-store' })
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
          return res;
        })
        .catch(() => caches.match(e.request))
    );
  } else if (isStatic) {
    // 静的アセット: キャッシュファースト
    e.respondWith(
      caches.match(e.request).then(r => r || fetch(e.request).then(res => {
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
        return res;
      }))
    );
  }
  // Supabase API 等のクロスオリジンリクエストは素通り
});
