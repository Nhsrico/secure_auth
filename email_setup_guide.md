# Email Service Configuration Guide

## Overview
This guide helps you configure email services for your SecureAuth production deployment. The system supports multiple email providers with automatic fallback.

## Supported Email Providers

### 1. SendGrid (Recommended)
**Best for**: High deliverability, reliable service, good free tier

**Setup Steps**:
1. Create account at [SendGrid](https://sendgrid.com/)
2. Generate API key in Settings > API Keys
3. Configure in Fly.io:
```bash
fly secrets set SENDGRID_API_KEY="your-sendgrid-api-key"
fly secrets set EMAIL_DOMAIN="secure-auth-prod.fly.dev"
```

### 2. Mailgun
**Best for**: Developer-friendly, good for transactional emails

**Setup Steps**:
1. Create account at [Mailgun](https://www.mailgun.com/)
2. Add and verify your domain
3. Get API key from Settings
4. Configure in Fly.io:
```bash
fly secrets set MAILGUN_API_KEY="your-mailgun-api-key"
fly secrets set EMAIL_DOMAIN="secure-auth-prod.fly.dev"
```

### 3. Postmark
**Best for**: Fast delivery, excellent reputation

**Setup Steps**:
1. Create account at [Postmark](https://postmarkapp.com/)
2. Create server and get Server Token
3. Configure in Fly.io:
```bash
fly secrets set POSTMARK_API_KEY="your-postmark-server-token"
fly secrets set EMAIL_DOMAIN="secure-auth-prod.fly.dev"
```

### 4. Amazon SES
**Best for**: AWS integration, cost-effective at scale

**Setup Steps**:
1. Set up Amazon SES in AWS Console
2. Create IAM user with SES permissions
3. Configure in Fly.io:
```bash
fly secrets set AWS_ACCESS_KEY_ID="your-aws-access-key"
fly secrets set AWS_SECRET_ACCESS_KEY="your-aws-secret-key"
fly secrets set AWS_REGION="us-east-1"
fly secrets set EMAIL_DOMAIN="secure-auth-prod.fly.dev"
```

## Quick Setup - SendGrid (Recommended)

### Step 1: Create SendGrid Account
1. Visit [SendGrid](https://sendgrid.com/) and sign up
2. Verify your email and complete account setup
3. Note: Free tier includes 100 emails/day

### Step 2: Generate API Key
1. Go to Settings > API Keys
2. Click "Create API Key"
3. Choose "Restricted Access"
4. Grant "Mail Send" permissions
5. Copy the generated API key

### Step 3: Configure in Production
```bash
# Set SendGrid API key
fly secrets set SENDGRID_API_KEY="SG.your-actual-api-key-here"

# Set email domain (optional, defaults to your app domain)
fly secrets set EMAIL_DOMAIN="secure-auth-prod.fly.dev"

# Deploy with new configuration
fly deploy
```

## Testing Email Configuration

After configuring your email service, test it by:

1. **Register a new user** - Should receive confirmation email
2. **Request password reset** - Should receive reset instructions
3. **Check application logs**:
```bash
fly logs
```

## Email Templates Included

The system includes professional email templates for:
- ✅ **Account Confirmation** - Welcome new users
- ✅ **Magic Link Login** - Passwordless authentication
- ✅ **Password Reset** - Secure password recovery
- ✅ **Security Alerts** - 2FA changes, suspicious activity

## Troubleshooting

### Common Issues:

**Emails not sending?**
- Check `fly logs` for error messages
- Verify API key is correct
- Ensure domain is verified with provider

**Emails going to spam?**
- Set up SPF, DKIM, DMARC records
- Use verified sender domain
- Check provider reputation guidelines

**Rate limiting?**
- Most providers have daily/hourly limits
- Monitor usage in provider dashboard
- Consider upgrading plan if needed

## Production Best Practices

1. **Use verified domains** for better deliverability
2. **Set up monitoring** for failed sends
3. **Configure webhooks** for delivery tracking
4. **Test regularly** to ensure service reliability
5. **Have backup provider** configured

## Next Steps

Once email is configured:
1. Test all email flows (registration, login, reset)
2. Set up domain verification for better deliverability
3. Monitor email delivery rates and reputation
4. Consider setting up email analytics
