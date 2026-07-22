# ZABTEC Scholarship Portal

Flutter student and ZABTEC admin portal with the Express/MongoDB API in
`backend/backend`.

## Run the complete app locally

The local backend includes its own persistent development MongoDB, so Docker
and a separately installed MongoDB are not required.

Terminal 1:

```bash
cd backend/backend
npm install
npm run dev:local
```

Terminal 2:

```bash
flutter pub get
flutter run -d chrome --web-port 8080
```

Open `http://localhost:8080`. Debug web builds use
`http://127.0.0.1:5000/api/v1` automatically. Release builds continue to use
the hosted API.

The local ZABTEC admin account is:

- Email: `admin@zabtec.local`
- Password: `Admin@Zabtec2026`

Local data persists under `backend/backend/.local-mongo/`.

For a physical phone on the same Wi-Fi, pass the Mac's LAN address explicitly:

```bash
flutter run -d <device-id> \
  --dart-define=LOCAL_NETWORK_API_BASE_URL=http://<mac-lan-ip>:5000/api/v1
```

The payment flow is `awaiting_payment` after challan generation,
`proof_submitted` after the student uploads a bank-stamped copy, and `approved`
only after a ZABTEC admin reviews and approves that image.

## Connect a hosted backend

No Flutter source change is required when the backend engineer supplies the
final HTTPS API URL. Build or run the app with the URL ending in `/api/v1`:

```bash
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1

flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

The backend must allow the deployed web origin through CORS and must retain the
same `/api/v1` routes. `https://apiapply.zabtec.co/api/v1` remains the fallback
for release builds when no `API_BASE_URL` is supplied.

## Customer support

Every student has a private support conversation with an automatic ZABTEC
welcome message. Students send messages from the floating support button, and
ZABTEC admins reply, close, or reopen conversations from **Support chats**.
