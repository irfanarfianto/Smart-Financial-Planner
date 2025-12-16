import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }

// Setup Supabase Client
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}

Deno.serve(async (req) => {
  try {
    // 1. Get Access Token from Firebase
    const accessToken = await getAccessToken({
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key,
    })

    // 2. Determine Target Time (UTC+7 for WIB) - Precision: Minute
    const now = new Date();
    // Add 7 hours to UTC time manually to get WIB Date object
    // Note: This creates a new Date object shifted by 7 hours to simulate WIB 
    const wibDate = new Date(now.getTime() + (7 * 60 * 60 * 1000));
    
    const wibHour = wibDate.getUTCHours();
    const wibMinute = wibDate.getUTCMinutes();

    const targetTimeFull = `${wibHour.toString().padStart(2, '0')}:${wibMinute.toString().padStart(2, '0')}:00`; // e.g., "20:30:00"

    console.log(`Running Check at WIB: ${targetTimeFull}`);

    // 3. Get Users matching this specific HH:mm:00
    const { data: usersToNotify, error: userError } = await supabase
      .from('profiles')
      .select(`
        id,
        full_name,
        daily_reminder_time,
        user_devices!inner(fcm_token)
      `)
      .eq('daily_reminder_time', targetTimeFull); // Exact match for TIME column

    if (userError) throw userError;
    if (!usersToNotify || usersToNotify.length === 0) {
      return new Response(JSON.stringify({ message: `No users scheduled for ${targetTimeFull} WIB` }), { headers: { "Content-Type": "application/json" } });
    }

    const userIds = usersToNotify.map(u => u.id);
    console.log(`Found ${usersToNotify.length} users for time ${targetTimeFull}`);
    
    // Map devices and carry over the user's name
    const devices = usersToNotify.flatMap(u => u.user_devices.map(d => ({ 
        user_id: u.id, 
        fcm_token: d.fcm_token,
        name: u.full_name ? u.full_name.split(' ')[0] : 'Bestie' // Ambil nama depan saja atau 'Bestie'
    })));

    // 4. Check Transactions (Optimization: Only notify those who haven't transacted today)
    // Use WIB date (not UTC) to match user's local timezone
    // Reuse wibDate from above (already calculated)
    const todayDateWIB = wibDate.toISOString().split('T')[0]; // e.g., "2025-12-16"
    
    const { data: transactingUsers, error: transError } = await supabase
        .from('transactions')
        .select('user_id')
        .in('user_id', userIds) // Only check relevant users
        .gte('transaction_date', `${todayDateWIB}T00:00:00`)
        .lte('transaction_date', `${todayDateWIB}T23:59:59`);
    
    if (transError) throw transError;

    const activeUserIds = new Set(transactingUsers.map(t => t.user_id));
    const targetDevices = devices.filter(d => !activeUserIds.has(d.user_id));

    if (targetDevices.length === 0) {
      return new Response(JSON.stringify({ message: "Selected users have already transacted." }), { headers: { "Content-Type": "application/json" } });
    }

    // --- GEN Z MESSAGES COLLECTION ---
    const getGenZMessage = (name: string) => {
        const messages = [
            { title: "Waduh 😭", body: `Dompet ${name} nangis diem-diem nih. Catet pengeluaran dulu yuk biar ga boncos!` },
            { title: "Pov: Lagi Healing 🗿", body: `${name} jangan ghosting duit sendiri dong! Yuk catet pengeluaran hari ini.` },
            { title: "Jujurly... 🤔", body: `${name}, hari ini jajan apa aja? Spill di sini biar keuangan tetep slay!` },
            { title: "Info Penting 👻", body: `Duit ${name} ga bakal ilang kok, tapi kalo ga dicatet jadi misteri ilahi. Yuk catet!` },
            { title: "Lho Belum Absen? 😮‍💨", body: `Yaaaah ${name} belum absen duit hari ini. Gas tipis-tipis catet pengeluaran bentar!` },
            { title: "Reminder Kece ⚡", body: `Halo ${name} yang kece badai! Jangan lupa catet duitnya biar ga tantrum akhir bulan.` },
            { title: "Misi Paket! 📦", body: `Ada tanggungan catet duit buat ${name} nih. Yuk unboxing aplikasinya bentar.` },
            { title: "Cek Khodam 🐍", body: `${name}! Khodam keuangannya bilang harus catet pengeluaran sekarang juga!` },
            { title: "Ga Bahaya Ta? 🥶", body: `Ga bahaya ta kalo ${name} lupa catet duit? Mending catet sekarang biar tidur nyenyak.` },
            { title: "Manifesting Kaya ✨", body: `Manifesting keuangan sehat buat ${name}. Tapi usaha dikit dong, catet pengeluaran hari ini ya!` }
        ];
        return messages[Math.floor(Math.random() * messages.length)];
    };

    // 4. Prepare Notifications
    const readyToSend = targetDevices.map(d => {
        const msg = getGenZMessage(d.name);
        return {
            ...d,
            notification: msg
        };
    });
    
    // Prepare notifications to insert in batch
    const notificationsToInsert = readyToSend.map(d => ({
        user_id: d.user_id,
        title: d.notification.title,
        body: d.notification.body,
        type: "REMINDER",
        data: { route: "/add-transaction" }
    }));

    // Insert to DB first
    const { error: insertError } = await supabase.from('notifications').insert(notificationsToInsert);
    if (insertError) {
        console.error("Error logging notifications:", insertError);
    }

    // Send Push
    const results = [];
    for (const item of readyToSend) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: item.fcm_token,
              notification: {
                title: item.notification.title,
                body: item.notification.body,
              },
              android: {
                priority: "high",
                notification: {
                   channel_id: "reminder_channel"
                }
              },
              data: {
                route: "/add-transaction",
                category: "reminder"
              }
            },
          }),
        }
      )
      
      const resData = await res.json()
      results.push({ user_id: item.user_id, status: res.status, data: resData });
    }

    return new Response(
      JSON.stringify({ message: "Reminders processed", count: results.length, details: results }),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (error) {
    console.error("CRITICAL ERROR:", error);
    return new Response(
      JSON.stringify({ error: (error as any).message || error, stack: (error as any).stack }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    )
  }
})
