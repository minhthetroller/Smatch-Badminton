# Environment Variables Implementation Guide

## Problem Statement

GitGuardian detected hardcoded secrets (Facebook App Keys and Google OAuth credentials) in the iOS configuration file `ios/Runner/Info.plist`. Hardcoded secrets in version control pose significant security risks.

## Solution Overview

This project implements a secure environment-based configuration system that:

1. Stores sensitive credentials in a local `.env` file (gitignored)
2. Uses placeholder variables in configuration files
3. Injects environment variables at build time via a shell script

## Implementation Details

### 1. Environment Variables Configuration

**File: `.env.example`**
- Template file with placeholder values
- Committed to version control as documentation
- Developers copy this to `.env` and fill in real values

**File: `.env`** (gitignored)
- Contains actual secret values
- Never committed to version control
- Each developer maintains their own copy

### 2. iOS Configuration

**File: `ios/Runner/Info.plist`**
- Uses Xcode build variables: `$(VARIABLE_NAME)`
- Example:
  ```xml
  <key>FacebookAppID</key>
  <string>$(FACEBOOK_APP_ID)</string>
  ```

**File: `ios/scripts/env_config.sh`**
- Shell script that runs during Xcode build phase
- Reads `.env` file from project root
- Generates `Flutter/EnvConfig.xcconfig` with environment variables
- Xcode uses `.xcconfig` to substitute variables in `Info.plist`

**File: `ios/.gitignore`**
- Excludes generated `Flutter/EnvConfig.xcconfig` from version control

### 3. Documentation

**File: `ios/README.md`**
- Step-by-step setup guide for iOS developers
- Instructions for adding the build script to Xcode
- CI/CD integration examples

**File: `SECURITY.md`**
- Security best practices
- Incident response procedures
- Secrets management guidelines

**File: `README.md`** (updated)
- Added environment configuration section
- Links to detailed setup guides

## Usage

### Local Development

1. Copy environment template:
   ```bash
   cp .env.example .env
   ```

2. Fill in credentials in `.env`:
   ```bash
   FACEBOOK_APP_ID=your_actual_app_id
   FACEBOOK_CLIENT_TOKEN=your_actual_token
   GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.your_actual_id
   ```

3. For iOS, add build script to Xcode (one-time setup):
   - Open `Runner.xcodeproj`
   - Select Runner target → Build Phases
   - Add Run Script Phase before "Compile Sources":
     ```bash
     "${SRCROOT}/scripts/env_config.sh"
     ```

4. Build the project normally - environment variables are injected automatically

### CI/CD Integration

In GitHub Actions or other CI platforms:

```yaml
- name: Create environment file
  run: |
    cat > .env << 'EOF'
    FACEBOOK_APP_ID=${{ secrets.FACEBOOK_APP_ID }}
    FACEBOOK_CLIENT_TOKEN=${{ secrets.FACEBOOK_CLIENT_TOKEN }}
    GOOGLE_REVERSED_CLIENT_ID=${{ secrets.GOOGLE_REVERSED_CLIENT_ID }}
    EOF

- name: Build iOS
  run: flutter build ios
```

## Security Benefits

1. ✅ **No secrets in version control** - All credentials stay in local `.env` files
2. ✅ **Per-developer credentials** - Each developer can use their own test credentials
3. ✅ **Per-environment configuration** - Different credentials for dev/staging/prod
4. ✅ **GitGuardian compliance** - No more secret detection alerts
5. ✅ **Easy credential rotation** - Just update `.env` file
6. ✅ **CI/CD compatible** - Works with secret management systems

## Migration from Hardcoded Secrets

If you previously committed hardcoded secrets:

1. **Rotate the secrets immediately** - Generate new keys/tokens
2. Apply this implementation
3. Update your `.env` file with new credentials
4. Never use the old exposed credentials again

## Troubleshooting

### Build fails with "variable not found" error

- Ensure `.env` file exists in project root
- Check that variable names in `.env` match exactly
- Verify the build script runs before compilation

### App crashes on launch with OAuth errors

- Verify credentials in `.env` are correct
- Check that the build script successfully generated `EnvConfig.xcconfig`
- Confirm variables are properly substituted in `Info.plist`

### CI/CD builds failing

- Ensure secrets are configured in CI platform
- Verify `.env` file is created before build step
- Check CI logs for script execution errors

## Additional Resources

- [Facebook OAuth Setup](https://developers.facebook.com/docs/ios/getting-started/)
- [Google OAuth Setup](https://developers.google.com/identity/sign-in/ios/start-integrating)
- [Xcode Build Configuration](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)
