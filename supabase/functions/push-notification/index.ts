// Supabase Edge Function: push-notification
//
// Dipicu oleh trigger pg_net `trigger_push_notification` (INSERT pada
// public.notifications — lihat migration 20260712100000_push_notification_trigger.sql)
// dan meneruskan notifikasi sebagai push FCM (HTTP v1) ke perangkat penerima.
//
// STATUS DEPLOY: sudah terdeploy (verify_jwt aktif; trigger mengirim anon key).
// Setup tersisa (sekali): set secret service account Firebase via
// Dashboard > Edge Functions > Secrets, atau CLI:
//   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
// (Service account JSON: Firebase Console > Project Settings > Service
//  Accounts > Generate new private key.)
//
// Penerima:
//   - user_id terisi  -> hanya token milik user tersebut.
//   - user_id null    -> broadcast ke semua anggota store (store_members).
//   - metadata.sender_id (bila ada) dikecualikan agar pengirim tidak
//     menerima push dari notifikasinya sendiri.

import { createClient } from "npm:@supabase/supabase-js@2";

type WebhookPayload = {
  type: "INSERT";
  table: string;
  record: {
    id: string;
    store_id: string | null;
    user_id: string | null;
    type: string | null;
    title: string | null;
    message: string | null;
    image_url: string | null;
    metadata: Record<string, unknown> | null;
  };
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

// ===== OAuth2: tukar JWT service account dengan access token Google =====

function base64UrlEncode(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pkcs8 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const raw = Uint8Array.from(atob(pkcs8), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    raw,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64UrlEncode(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;

  const key = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`Gagal mengambil access token Google: ${await res.text()}`);
  }
  const json = await res.json();
  return json.access_token as string;
}

// ===== Kirim satu pesan FCM; kembalikan false bila token invalid =====

async function sendFcm(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  record: WebhookPayload["record"],
): Promise<{ ok: boolean; invalidToken: boolean }> {
  const body = {
    message: {
      token: fcmToken,
      notification: {
        title: record.title ?? "Pemberitahuan Baru",
        body: record.message ?? "",
      },
      data: {
        id: record.id ?? "",
        store_id: record.store_id ?? "",
        user_id: record.user_id ?? "",
        type: record.type ?? "info",
        title: record.title ?? "",
        message: record.message ?? "",
        image_url: record.image_url ?? "",
        metadata: record.metadata ? JSON.stringify(record.metadata) : "",
      },
      android: {
        priority: "HIGH",
        notification: {
          channel_id: channelIdForType(record.type),
        },
      },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    },
  };

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );

  if (res.ok) return { ok: true, invalidToken: false };

  const errText = await res.text();
  console.error(`FCM error (${res.status}): ${errText}`);
  // 404 UNREGISTERED / 400 INVALID_ARGUMENT = token mati, hapus dari DB
  const invalidToken = res.status === 404 ||
    errText.includes("UNREGISTERED") ||
    errText.includes("INVALID_ARGUMENT");
  return { ok: false, invalidToken };
}

// Selaras dengan LocalNotificationService.channelForType di aplikasi Flutter
function channelIdForType(type: string | null): string {
  switch (type) {
    case "stock":
    case "low_stock":
    case "out_of_stock":
      return "stok_channel";
    case "transaction":
    case "transaction_void":
    case "payment":
    case "success":
      return "transaksi_channel";
    case "reminder":
      return "reminder_channel";
    default:
      return "sistem_channel";
  }
}

Deno.serve(async (req) => {
  try {
    const payload = (await req.json()) as WebhookPayload;

    if (payload.type !== "INSERT" || payload.table !== "notifications") {
      return new Response(JSON.stringify({ skipped: true }), { status: 200 });
    }

    const record = payload.record;
    const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!saRaw) throw new Error("Secret FCM_SERVICE_ACCOUNT belum diset.");
    const serviceAccount = JSON.parse(saRaw) as ServiceAccount;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Tentukan user penerima
    let userIds: string[] = [];
    if (record.user_id) {
      userIds = [record.user_id];
    } else if (record.store_id) {
      const { data: members, error } = await supabase
        .from("store_members")
        .select("user_id")
        .eq("store_id", record.store_id);
      if (error) throw error;
      userIds = (members ?? []).map((m) => m.user_id as string);
    }

    // Jangan kirim push ke pengirim notifikasinya sendiri
    const senderId = record.metadata?.["sender_id"] as string | undefined;
    if (senderId) {
      userIds = userIds.filter((id) => id !== senderId);
    }

    if (userIds.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: "no recipients" }), {
        status: 200,
      });
    }

    // Ambil seluruh token FCM milik user penerima
    const { data: tokens, error: tokenError } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token")
      .in("user_id", userIds);
    if (tokenError) throw tokenError;

    const fcmTokens = (tokens ?? []).map((t) => t.fcm_token as string);
    if (fcmTokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, reason: "no tokens" }), {
        status: 200,
      });
    }

    const accessToken = await getAccessToken(serviceAccount);

    let sent = 0;
    const invalidTokens: string[] = [];
    await Promise.all(fcmTokens.map(async (token) => {
      const result = await sendFcm(
        accessToken,
        serviceAccount.project_id,
        token,
        record,
      );
      if (result.ok) sent++;
      if (result.invalidToken) invalidTokens.push(token);
    }));

    // Bersihkan token yang sudah tidak berlaku
    if (invalidTokens.length > 0) {
      await supabase.from("user_fcm_tokens").delete().in("fcm_token", invalidTokens);
    }

    return new Response(
      JSON.stringify({ sent, cleaned: invalidTokens.length }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("push-notification error:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
