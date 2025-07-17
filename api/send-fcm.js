import { GoogleAuth } from 'google-auth-library';

const PROJECT_ID = 'fouda-market';
const SERVICE_ACCOUNT = JSON.parse(process.env.FCM_SERVICE_ACCOUNT_JSON);

export default async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    const { fcmToken, title, body, data } = req.body;

    const auth = new GoogleAuth({
        credentials: SERVICE_ACCOUNT,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    const client = await auth.getClient();
    const accessToken = await client.getAccessToken();

    const message = {
        message: {
            token: fcmToken,
            notification: { title, body },
            data: data || {},
        },
    };

    const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
        {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken.token}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(message),
        }
    );

    const result = await response.json();
    res.status(200).json(result);
} 