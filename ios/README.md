# iOS Configuration Guide

## Environment Variables Setup

This project uses environment variables to securely manage sensitive configuration like OAuth credentials. Hardcoded secrets are not allowed in the repository.

### Setup Steps

1. **Copy the environment template:**
   ```bash
   cp ../.env.example ../.env
   ```

2. **Fill in your credentials in `.env`:**
   ```bash
   # Facebook Configuration
   FACEBOOK_APP_ID=your_facebook_app_id_here
   FACEBOOK_CLIENT_TOKEN=your_facebook_client_token_here
   
   # Google OAuth Configuration
   GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.your_client_id_here
   ```

3. **Get your credentials:**
   - **Facebook:** Visit [Facebook Developers](https://developers.facebook.com/) to create an app and get your App ID and Client Token
   - **Google:** Visit [Google Cloud Console](https://console.cloud.google.com/) to set up OAuth and get your reversed client ID

### How It Works

1. The `ios/scripts/env_config.sh` script runs during the Xcode build process
2. It reads the `.env` file from the project root
3. It generates `Flutter/EnvConfig.xcconfig` with the environment variables
4. Xcode uses these variables to replace placeholders in `Info.plist`:
   - `$(FACEBOOK_APP_ID)` → Your Facebook App ID
   - `$(FACEBOOK_CLIENT_TOKEN)` → Your Facebook Client Token
   - `$(GOOGLE_REVERSED_CLIENT_ID)` → Your Google Reversed Client ID

### Adding the Build Script to Xcode

To enable automatic environment variable injection:

1. Open `Runner.xcodeproj` in Xcode
2. Select the **Runner** target
3. Go to **Build Phases**
4. Click **+** → **New Run Script Phase**
5. Add this script **before** "Compile Sources":
   ```bash
   "${SRCROOT}/scripts/env_config.sh"
   ```
6. Name it "Generate Environment Config"

### CI/CD Setup

For continuous integration environments (like GitHub Actions):

- The script automatically handles missing `.env` files by creating empty values (not placeholder text)
- You should set up environment secrets in your CI/CD platform
- Create a step to generate the `.env` file before building:
  ```yaml
  - name: Create .env file
    run: |
      echo "FACEBOOK_APP_ID=\"${{ secrets.FACEBOOK_APP_ID }}\"" >> .env
      echo "FACEBOOK_CLIENT_TOKEN=\"${{ secrets.FACEBOOK_CLIENT_TOKEN }}\"" >> .env
      echo "GOOGLE_REVERSED_CLIENT_ID=\"${{ secrets.GOOGLE_REVERSED_CLIENT_ID }}\"" >> .env
  ```

### Security Notes

- **Never commit** the `.env` file to version control (it's in `.gitignore`)
- **Never commit** hardcoded secrets in `Info.plist` or any other source file
- The generated `Flutter/EnvConfig.xcconfig` is also excluded from version control
- Always use placeholders like `$(VARIABLE_NAME)` in configuration files
