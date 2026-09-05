# Continuous Integration & TestFlight Delivery

Nom Nom uses **GitHub Actions** (`.github/workflows/testflight.yml`) to automatically build, sign, and deliver new builds to **TestFlight** on every commit pushed to `main`.

---

## How It Works

1. **Trigger**: Pushing to `main` (or clicking **Run workflow** in GitHub's Actions tab).
2. **Environment**: Apple Silicon `macos-14` runner with Xcode 16.
3. **Macro Validation**: Bypasses Xcode package/macro security prompts in CI.
4. **Versioning**: Sets `CURRENT_PROJECT_VERSION` dynamically to `${{ github.run_number }}` so every build uploaded to App Store Connect is guaranteed to have a unique, incrementing build number.
5. **Signing**: Imports your Apple Distribution Certificate into a temporary CI keychain and applies the App Store Provisioning Profile.
6. **Artifacting**: Saves `NomNom.ipa` as an artifact on the GitHub run for debugging or local archiving.
7. **Upload**: Uses your App Store Connect API Key to upload the IPA directly to TestFlight.

---

## Required GitHub Repository Secrets

Navigate to your GitHub repository:
**Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

You need to add the following **6 secrets**:

| Secret Name | Description | Example / Format |
| :--- | :--- | :--- |
| `APP_STORE_CONNECT_KEY_ID` | Key ID of your App Store Connect API Key | `2X9R4HXF34` (10 chars) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from App Store Connect | `57246542-96fe-1a63-e053-0824d011072a` (UUID) |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Full text content of the `.p8` key file | `-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----` |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded Apple Distribution `.p12` | Raw base64 string |
| `P12_PASSWORD` | Password used when exporting the `.p12` certificate | Plain text string |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded `.mobileprovision` file | Raw base64 string |

---

## Generating the Credentials (Step-by-Step)

### 1. App Store Connect API Key (`.p8`)

1. Open [App Store Connect: Users and Access](https://appstoreconnect.apple.com/access/integrations/api).
2. Select the **Integrations** (or **Keys**) tab → **App Store Connect API**.
3. Click **+** (Generate API Key).
   - **Name**: `GitHub Actions TestFlight`
   - **Access**: **App Manager** or **Admin** (required for uploading builds).
4. Note the **Issuer ID** at the top → copy into `APP_STORE_CONNECT_ISSUER_ID`.
5. Note the **Key ID** in the table → copy into `APP_STORE_CONNECT_KEY_ID`.
6. Click **Download API Key** (`AuthKey_<KeyID>.p8`).
   > [!IMPORTANT]
   > Apple only lets you download this file **once**.
7. Open the downloaded `.p8` file in a text editor (or `cat AuthKey_*.p8 | pbcopy`) and paste the complete content into `APP_STORE_CONNECT_PRIVATE_KEY`.

---

### 2. Apple Distribution Certificate (`.p12`)

1. Open **Keychain Access** on your Mac.
2. Under **login** keychain, click **My Certificates** in the sidebar.
3. Look for **Apple Distribution: Joel Sanden (D4F66LSYSF)**.
   - Expand the row to ensure the private key is nested under the certificate.
4. Right-click the certificate → select **Export "Apple Distribution: Joel Sanden..."**.
5. Save as `distribution.p12`.
6. Enter a strong password when prompted → copy this password into `P12_PASSWORD`.
7. In Terminal, encode the `.p12` file to base64 and copy it to your clipboard:
   ```bash
   base64 -i distribution.p12 | pbcopy
   ```
8. Paste this into `BUILD_CERTIFICATE_BASE64`.

---

### 3. Provisioning Profile (`.mobileprovision`)

1. Go to [Apple Developer: Profiles](https://developer.apple.com/account/resources/profiles/list).
2. Click **+** to register a new profile.
3. Select **App Store Connect** under Distribution → click **Continue**.
4. **App ID**: Select `se.joelsanden.nomnom`.
5. **Certificates**: Select your Apple Distribution Certificate (`Joel Sanden`).
6. **Profile Name**: `NomNom AppStore`.
7. Click **Generate** and then **Download** (you will get `NomNom_AppStore.mobileprovision`).
8. In Terminal, encode the profile to base64 and copy it to your clipboard:
   ```bash
   base64 -i ~/Downloads/NomNom_AppStore.mobileprovision | pbcopy
   ```
9. Paste this into `BUILD_PROVISION_PROFILE_BASE64`.

---

## Verifying the First Automated Build

1. Push your changes to `main`:
   ```bash
   git push origin main
   ```
2. Go to your GitHub repository and click the **Actions** tab.
3. Click on the running **Deploy to TestFlight** workflow to monitor build progress.
4. When the build succeeds:
   - The `.ipa` is preserved in the **Artifacts** section of the run.
   - The build is transmitted to App Store Connect.
5. In [App Store Connect: Apps](https://appstoreconnect.apple.com/apps) → **Nom Nom** → **TestFlight**:
   - The build will show under **iOS Builds** in "Processing" state for ~5–10 minutes.
   - Once processing finishes, it is automatically available to your **Internal Testing** group.
