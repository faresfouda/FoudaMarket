// Vercel Edge Config for Firebase
// هذا الملف يساعد في حل مشاكل CORS و Firebase على Vercel

export default async function handler(request) {
  // إضافة headers للـ CORS
  const headers = new Headers({
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Max-Age': '86400',
  });

  // التعامل مع طلبات OPTIONS (preflight)
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers });
  }

  // معالجة طلبات Firebase
  if (request.url.includes('firebase')) {
    try {
      // إعادة توجيه طلبات Firebase مع headers صحيحة
      const response = await fetch(request.url, {
        method: request.method,
        headers: request.headers,
        body: request.method !== 'GET' ? await request.arrayBuffer() : undefined,
      });

      // إضافة CORS headers للاستجابة
      const responseHeaders = new Headers(response.headers);
      headers.forEach((value, key) => {
        responseHeaders.set(key, value);
      });

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: responseHeaders,
      });
    } catch (error) {
      console.error('Firebase request error:', error);
      return new Response(JSON.stringify({ error: 'Firebase request failed' }), {
        status: 500,
        headers: { ...headers, 'Content-Type': 'application/json' },
      });
    }
  }

  // للطلبات الأخرى، إرجاع 404
  return new Response('Not Found', { status: 404, headers });
}
