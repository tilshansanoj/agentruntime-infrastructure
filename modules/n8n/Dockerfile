FROM n8nio/n8n
# Switch to root to install packages globally
USER root
# Install npm packages globally
RUN npm install -g moment lodash stytch resend aws-sdk nodemailer jwt-decode axios jsonwebtoken uuid
# Switch back to the n8n user to run the application
USER node
# Expose the port
EXPOSE 5678