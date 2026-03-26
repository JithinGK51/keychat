import smtplib
import threading
import os
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

load_dotenv()

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

EMAIL_USER = os.getenv("EMAIL_USER")
EMAIL_PASS = os.getenv("EMAIL_PASS")
SENDER_NAME = "Crafzio" # Using the brand name from reference

def send_email_sync(recipient, subject, html_body):
    if not EMAIL_USER or not EMAIL_PASS:
        logger.error("SMTP credentials not found in environment")
        return False
    
    try:
        print(f"DEBUG: Attempting to send email to {recipient}...")
        msg = MIMEMultipart('alternative')
        msg['From'] = f"{SENDER_NAME} <{EMAIL_USER}>"
        msg['To'] = recipient
        msg['Subject'] = subject
        msg.attach(MIMEText(html_body, 'html'))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465, timeout=15) as server:
            server.login(EMAIL_USER, EMAIL_PASS)
            server.send_message(msg)
        
        print(f"DEBUG: Email SENT successfully to {recipient}")
        return True
    except Exception as e:
        print(f"DEBUG: FAILED to send email to {recipient}: {e}")
        return False

def send_email_async(recipient, subject, html_body):
    """Fire-and-forget email in a background thread."""
    thread = threading.Thread(target=send_email_sync, args=(recipient, subject, html_body))
    thread.daemon = True
    thread.start()

def get_otp_html(otp_code, purpose="verification"):
    """
    Modern Email Template inspired by the user's reference.
    purpose can be 'verification' or 'reset'.
    """
    title = "Email Verification" if purpose == "verification" else "Password Reset"
    subtitle = "Use the code below to verify your account" if purpose == "verification" else "Use the code below to reset your password"
    theme_color = "#a78bfa" if purpose == "verification" else "#f43f5e" # Purple for verify, Rose for reset
    
    return f"""
    <div style="font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 500px; margin: 40px auto; padding: 40px; background: #0f172a; border-radius: 24px; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); color: #f8fafc; text-align: center;">
        <div style="margin-bottom: 32px;">
            <div style="display: inline-block; padding: 12px; background: linear-gradient(135deg, {theme_color}, #7c3aed); border-radius: 16px; margin-bottom: 16px;">
                 <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
            </div>
            <h1 style="margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.025em; color: #fff;">{title}</h1>
            <p style="margin-top: 8px; color: #94a3b8; font-size: 15px;">{subtitle}</p>
        </div>
        
        <div style="margin: 32px 0; padding: 24px; background: rgba(255,255,255,0.03); border: 1px dashed rgba(255,255,255,0.1); border-radius: 16px;">
            <span style="display: block; font-family: 'JetBrains Mono', monospace; font-size: 42px; font-weight: 800; letter-spacing: 8px; color: {theme_color}; text-shadow: 0 0 20px rgba(167, 139, 250, 0.3);">{otp_code}</span>
        </div>
        
        <p style="margin-bottom: 32px; color: #64748b; font-size: 13px;">This code will expire in 10 minutes. If you didn't request this, please ignore this email.</p>
        
        <div style="padding-top: 32px; border-top: 1px solid rgba(255,255,255,0.05);">
            <p style="margin: 0; font-size: 14px; font-weight: 600; color: #94a3b8;">Team Crafzio</p>
            <p style="margin: 4px 0 0 0; font-size: 12px; color: #475569;">© 2026 Crafzio Inc. All rights reserved.</p>
        </div>
    </div>
    """

def get_welcome_html(name):
    """Modern Welcome Email Template."""
    return f"""
    <div style="font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 500px; margin: 40px auto; padding: 40px; background: #0f172a; border-radius: 24px; border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); color: #f8fafc; text-align: center;">
        <div style="margin-bottom: 32px;">
            <div style="display: inline-block; padding: 12px; background: linear-gradient(135deg, #10b981, #34d399); border-radius: 16px; margin-bottom: 16px;">
                 <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
            </div>
            <h1 style="margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.025em; color: #fff;">Welcome to Crafzio, {name}! 🎉</h1>
            <p style="margin-top: 8px; color: #94a3b8; font-size: 15px;">Your journey with us begins now.</p>
        </div>
        
        <div style="margin: 32px 0; line-height: 1.6; color: #cbd5e1; font-size: 15px;">
            <p>We're thrilled to have you on board. Your account is now fully verified and ready to go.</p>
            <p style="margin-top: 16px;">🎊 Congratulations! You're all set. Open the app and log in to start your journey with KeyNote Chat.</p>
        </div>
        
        <div style="margin: 32px 0; padding: 20px; background: linear-gradient(135deg, rgba(124,58,237,0.15), rgba(167,139,250,0.1)); border: 1px solid rgba(167,139,250,0.3); border-radius: 16px;">
            <p style="margin: 0; font-size: 16px; font-weight: 700; color: #a78bfa;">✅ Account Verified Successfully</p>
            <p style="margin: 8px 0 0 0; font-size: 13px; color: #94a3b8;">You can now log in to KeyNote Chat with your credentials.</p>
        </div>
        
        <div style="margin-top: 40px; padding-top: 32px; border-top: 1px solid rgba(255,255,255,0.05);">
            <p style="margin: 0; font-size: 14px; font-weight: 600; color: #94a3b8;">Team Crafzio</p>
            <p style="margin: 4px 0 0 0; font-size: 12px; color: #475569;">You're receiving this because you signed up at crafzio.com</p>
        </div>
    </div>
    """
