# Deploying RoadEdge AI to Vercel

RoadEdge AI is pre-configured for deployment on [Vercel](https://vercel.com/) with zero manual compilation hassles.

---

## ⚡ Option 1: Automatic Git Deployment (Recommended)

1. Push this repository to your **GitHub / GitLab / Bitbucket** account:
   ```bash
   git add .
   git commit -m "feat: Add Vercel deployment configuration"
   git push origin main
   ```
2. Go to [Vercel Dashboard](https://vercel.com/new) and click **"Add New... -> Project"**.
3. Import your **RoadEdge AI** repository.
4. **Project Settings**:
   - **Framework Preset**: *Other*
   - **Root Directory**: `./` (Default)
   - **Build Command**: `node scripts/build.js` (Automatically populated from `vercel.json`)
   - **Output Directory**: `roadedge_ai/build/web` (Automatically populated from `vercel.json`)
5. Click **Deploy**. Vercel will bootstrap the build pipeline and deliver your high-performance web dashboard on global edge CDNs.

*(Note: If you choose `roadedge_ai` as your Root Directory in Vercel settings, a dedicated `roadedge_ai/vercel.json` is already present to serve `build/web` directly!)*

---

## 💻 Option 2: Deploy from CLI (Instant Pre-built)

If you have Flutter installed locally, you can deploy in seconds without server-side compilation:

1. **Install Vercel CLI** (if not already installed):
   ```bash
   npm install -g vercel
   ```

2. **Build and Deploy**:
   ```bash
   # From root:
   npm run build
   vercel --prod
   ```

---

## 🤖 Option 3: GitHub Actions Automated CI/CD

A production-ready workflow is included in [`.github/workflows/deploy-vercel.yml`](./.github/workflows/deploy-vercel.yml).

To activate it:
1. Add the following secrets in your GitHub repository (`Settings -> Secrets and variables -> Actions`):
   - `VERCEL_TOKEN`: Your Vercel personal access token
   - `VERCEL_ORG_ID`: Your Vercel team/user ID
   - `VERCEL_PROJECT_ID`: Your Vercel project ID
2. Every push to `main` will run tests, build the optimized Flutter release bundle, and deploy to Vercel automatically.

---

## 🛠️ Architecture Notes for Web

- **Conditional FFI Decoupling**: Native Android NNAPI / Qualcomm LiteRT bindings in `tflite_flutter` are decoupled via Dart conditional exports (`dart.library.io`), preventing `external` C-binding compilation errors in browsers.
- **Simulated Edge Engine on Web**: The Web build features the full real-time HUD, forward motion kinematics, manual hazard trigger controls, GeoJSON export, and telemetry metrics.
- **Optimized Caching & Headers**: `vercel.json` includes immutable cache headers for `.wasm`, `.js`, and assets, with SPA fallback routing to `index.html`.
- **Automotive Dark HUD Loader**: Features an animated HUD scanner loader matching the `#0A0E17` design system while Flutter Web initializes.
