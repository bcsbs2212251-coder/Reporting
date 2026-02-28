import smtplib
import secrets
import string
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta, timezone
import os
from dotenv import load_dotenv

load_dotenv()

class EmailService:
    def __init__(self):
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.email = os.getenv("GMAIL_EMAIL")
        self.password = os.getenv("GMAIL_APP_PASSWORD")  # Use App Password, not regular password
        
    def generate_reset_token(self, length=32):
        """Generate a secure random token for password reset"""
        alphabet = string.ascii_letters + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(length))
    
    def send_password_reset_email(self, to_email: str, user_name: str, reset_token: str):
        """Send password reset email"""
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "Password Reset - Molecule WorkFlow Pro"
            msg['From'] = self.email
            msg['To'] = to_email
            
            # Create HTML content
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                    .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                    .button {{ display: inline-block; background: #4CAF50; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                    .token-box {{ background: #e8f5e8; border: 1px solid #4CAF50; padding: 15px; border-radius: 5px; font-family: monospace; font-size: 18px; text-align: center; margin: 20px 0; }}
                    .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
                    .warning {{ background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🔐 Password Reset Request</h1>
                        <p>Molecule WorkFlow Pro</p>
                    </div>
                    <div class="content">
                        <h2>Hello {user_name},</h2>
                        <p>We received a request to reset your password for your Molecule WorkFlow Pro account.</p>
                        
                        <div class="warning">
                            <strong>⚠️ Security Notice:</strong> If you didn't request this password reset, please ignore this email. Your account is still secure.
                        </div>
                        
                        <p>To reset your password, use the following reset token:</p>
                        
                        <div class="token-box">
                            <strong>{reset_token}</strong>
                        </div>
                        
                        <p><strong>Instructions:</strong></p>
                        <ol>
                            <li>Go to the Molecule WorkFlow Pro login page</li>
                            <li>Click "Forgot Password?"</li>
                            <li>Enter your email address</li>
                            <li>Enter the reset token above</li>
                            <li>Create your new password</li>
                        </ol>
                        
                        <div class="warning">
                            <strong>⏰ Important:</strong> This reset token will expire in 1 hour for security reasons.
                        </div>
                        
                        <p>If you have any issues, please contact our support team.</p>
                        
                        <p>Best regards,<br>
                        <strong>Molecule WorkFlow Pro Team</strong></p>
                    </div>
                    <div class="footer">
                        <p>This is an automated email. Please do not reply to this message.</p>
                        <p>© 2026 Molecule WorkFlow Pro. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            # Create plain text version
            text_content = f"""
            Password Reset - Molecule WorkFlow Pro
            
            Hello {user_name},
            
            We received a request to reset your password for your Molecule WorkFlow Pro account.
            
            SECURITY NOTICE: If you didn't request this password reset, please ignore this email.
            
            To reset your password, use the following reset token:
            
            {reset_token}
            
            Instructions:
            1. Go to the Molecule WorkFlow Pro login page
            2. Click "Forgot Password?"
            3. Enter your email address
            4. Enter the reset token above
            5. Create your new password
            
            IMPORTANT: This reset token will expire in 1 hour for security reasons.
            
            Best regards,
            Molecule WorkFlow Pro Team
            
            This is an automated email. Please do not reply to this message.
            """
            
            # Attach parts
            part1 = MIMEText(text_content, 'plain')
            part2 = MIMEText(html_content, 'html')
            
            msg.attach(part1)
            msg.attach(part2)
            
            # Send email
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.email, self.password)
            text = msg.as_string()
            server.sendmail(self.email, to_email, text)
            server.quit()
            
            return True
            
        except Exception as e:
            print(f"Error sending email: {e}")
            return False
    
    def send_password_change_confirmation(self, to_email: str, user_name: str):
        """Send confirmation email after password change"""
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "Password Changed Successfully - Molecule WorkFlow Pro"
            msg['From'] = self.email
            msg['To'] = to_email
            
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                    .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                    .success {{ background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                    .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>✅ Password Changed Successfully</h1>
                        <p>Molecule WorkFlow Pro</p>
                    </div>
                    <div class="content">
                        <h2>Hello {user_name},</h2>
                        
                        <div class="success">
                            <strong>✅ Success!</strong> Your password has been changed successfully.
                        </div>
                        
                        <p>Your Molecule WorkFlow Pro account password was changed on {datetime.now(timezone.utc).strftime('%B %d, %Y at %I:%M %p UTC')}.</p>
                        
                        <p>If you didn't make this change, please contact our support team immediately.</p>
                        
                        <p>For your security:</p>
                        <ul>
                            <li>Make sure to use a strong, unique password</li>
                            <li>Don't share your password with anyone</li>
                            <li>Log out from shared devices</li>
                        </ul>
                        
                        <p>Best regards,<br>
                        <strong>Molecule WorkFlow Pro Team</strong></p>
                    </div>
                    <div class="footer">
                        <p>This is an automated email. Please do not reply to this message.</p>
                        <p>© 2026 Molecule WorkFlow Pro. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            text_content = f"""
            Password Changed Successfully - Molecule WorkFlow Pro
            
            Hello {user_name},
            
            Your password has been changed successfully.
            
            Your Molecule WorkFlow Pro account password was changed on {datetime.now(timezone.utc).strftime('%B %d, %Y at %I:%M %p UTC')}.
            
            If you didn't make this change, please contact our support team immediately.
            
            Best regards,
            Molecule WorkFlow Pro Team
            """
            
            part1 = MIMEText(text_content, 'plain')
            part2 = MIMEText(html_content, 'html')
            
            msg.attach(part1)
            msg.attach(part2)
            
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.email, self.password)
            text = msg.as_string()
            server.sendmail(self.email, to_email, text)
            server.quit()
            
            return True
            
        except Exception as e:
            print(f"Error sending confirmation email: {e}")
            return False

# Create global instance
email_service = EmailService()