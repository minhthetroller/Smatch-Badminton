# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it by creating a private security advisory on GitHub or by emailing the maintainers directly.

## Secrets Management

### ⚠️ Important Security Guidelines

1. **Never commit secrets** to version control:
   - API keys
   - OAuth credentials (Facebook, Google, etc.)
   - Database passwords
   - Private keys
   - Access tokens

2. **Use environment variables** for all sensitive configuration:
   - Store credentials in `.env` file (which is gitignored)
   - Use `.env.example` as a template (with placeholder values only)
   - Reference the [Setup Guide](README.md#setup) for configuration

3. **For iOS builds**:
   - Secrets are injected at build time from `.env` file
   - `Info.plist` uses placeholder variables like `$(FACEBOOK_APP_ID)`
   - The build script `ios/scripts/env_config.sh` handles the injection
   - See [ios/README.md](ios/README.md) for details

4. **For CI/CD**:
   - Store secrets in your CI platform's secret management (e.g., GitHub Secrets)
   - Never log or print secrets in CI logs
   - Generate `.env` file from secrets before building

### Secret Detection

This project uses GitGuardian to detect accidentally committed secrets. If you see a GitGuardian alert:

1. **Immediately rotate the exposed secret** (generate a new key/token)
2. Remove the secret from the code and replace with environment variable
3. Update your `.env` file with the new secret
4. Never commit the `.env` file

### Best Practices

- ✅ Use `.env` file for local development
- ✅ Use CI/CD secret management for deployments
- ✅ Use placeholder variables in configuration files
- ✅ Regularly rotate credentials
- ✅ Use least-privilege access for API keys
- ❌ Never commit `.env` files
- ❌ Never hardcode secrets in source code
- ❌ Never share secrets in chat/email/tickets
- ❌ Never use production credentials in development

## Dependencies Security

- Regularly update dependencies to patch security vulnerabilities
- Use `flutter pub outdated` to check for updates
- Review dependency advisories before updating

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Security Updates

Security patches will be released as needed. Always use the latest version of the app.
