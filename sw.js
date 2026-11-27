// Service worker: cho app chạy OFFLINE sau lần mở đầu tiên.
//  - "app"  : file của app (HTML, Leaflet, icon) → lấy từ cache trước, có mạng thì cập nhật ngầm
//  - "tiles": ô ảnh vệ tinh đã xem / đã tải sẵn → lấy từ cache, không có mới tải mạng
// Đổi số phiên bản khi sửa app để điện thoại nhận bản mới.
const APP_CACHE = "kiemdem-app-v6";
const TILE_CACHE = "kiemdem-tiles-v1";
// Không đưa "./" vào: một số server trả 404 cho thư mục → cả bước cài thất bại.
const APP_FILES = [
  "./index.html", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png",
  "./leaflet/leaflet.js", "./leaflet/leaflet.css",
  "./leaflet/images/layers.png", "./leaflet/images/layers-2x.png",
  "./leaflet/images/marker-icon.png", "./leaflet/images/marker-icon-2x.png", "./leaflet/images/marker-shadow.png",
];

self.addEventListener("install", e=>{
  e.waitUntil(caches.open(APP_CACHE).then(c=>c.addAll(APP_FILES)).then(()=>self.skipWaiting()));
});
self.addEventListener("activate", e=>{
  e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith("kiemdem-app-") && k !== APP_CACHE).map(k=>caches.delete(k))))
    .then(()=>self.clients.claim()));
});
self.addEventListener("fetch", e=>{
  const url = new URL(e.request.url);
  if(e.request.method !== "GET") return;
  if(url.hostname === "server.arcgisonline.com"){
    // Ảnh vệ tinh: cache trước
    e.respondWith(caches.open(TILE_CACHE).then(async c=>{
      const hit = await c.match(e.request.url);
      if(hit) return hit;
      const res = await fetch(e.request.url, {mode:"cors"});
      if(res.ok) c.put(e.request.url, res.clone());
      return res;
    }));
    return;
  }
  if(url.origin !== self.location.origin) return;
  // File của app: cache trước (chạy offline), cập nhật ngầm khi có mạng
  e.respondWith(caches.open(APP_CACHE).then(async c=>{
    // Mở "…/kiem-dem/" (không ghi index.html) → dùng bản index.html đã lưu
    const req = url.pathname.endsWith("/") ? new Request(url.origin + url.pathname + "index.html") : e.request;
    const hit = await c.match(req, {ignoreSearch:true});
    const net = fetch(e.request).then(res=>{ if(res.ok) c.put(e.request, res.clone()); return res; }).catch(()=>null);
    return hit || (await net) || new Response("Offline", {status:503});
  }));
});
