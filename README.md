# Cloudflare Trusted Proxies Caddy with Docker Compose

This project is designed to enhance the security and reliability of your Caddy-based reverse proxy setup, particularly when used in conjunction with Cloudflare. It ensures that your server is protected against potential IP spoofing and unauthorized access while maintaining a robust and automated configuration, without relying on unofficial modules.

## Key Security Considerations

### 1. Removing `X-Forwarded-For` Headers
Cloudflare does not automatically remove the `X-Forwarded-For` header from incoming requests. This can leave your server vulnerable to IP spoofing attacks. To mitigate this risk, ensure that your configuration explicitly removes or validates the `X-Forwarded-For` header.

### 2. Enabling Full (Strict) SSL Mode
To maximize security, enable Full (Strict) SSL mode in your Cloudflare settings. This ensures that all connections between Cloudflare and your origin server are encrypted and authenticated.

### 3. Configuring SSL Certificates
Generate and place your SSL certificates in the `caddy/ssl/` directory. These certificates are used to secure the connection between Cloudflare and your origin server. Additionally, enable authenticated origin pull to ensure that only Cloudflare can connect to your server.

### 4. Enabling Proxy DNS
Enable Proxy DNS in your Cloudflare settings to mask your origin server's IP address and protect it from direct access.

## How to Use This Project

### Prerequisites
- Docker and Docker Compose installed on your system.
- A Cloudflare account with your domain configured.
- SSL certificates generated and placed in the `caddy/ssl/` directory.

### Steps to Deploy

1. **Clone the Repository**

2. **Configure Cloudflare Settings**
   - `Rules ➜ Transform Rules` Create rules to remove the `X-Forwarded-For` header.
   - `SSL/TLS ➜ Configure encryption mode` Enable Full (Strict) SSL mode.
   - `SSL/TLS ➜ Origin Server` Set up authenticated origin pull. 
   - `DNS ➜ Records` Enable Proxy DNS for your domain.

3. **Automate Cloudflare IP Updates**
   - The script `update_cf_ips.sh` fetches the latest Cloudflare IP ranges and updates the Caddy configuration accordingly.
   - In `docker-compose.yml`, a service is set up to run this script periodically. You can adjust the frequency by modifying the sleep duration in the command:
     ```bash
     while true; do sleep 1800; /scripts/update_cf_ips.sh; done
     ```
   - If you want to adjust the time interval, modify the `sleep` duration. For example, to run the script every hour (3600 seconds):
     ```bash
     while true; do sleep 3600; /scripts/update_cf_ips.sh; done
     ```

4. **Start the Services**
   Use Docker Compose to start the services:
   ```bash
   docker-compose up -d
   ```

5. **Verify the Setup**
   - Ensure that the `caddy` service is running and accessible.
   - Check the logs to confirm that the trusted proxies list is being updated.

## Why This Project Matters

This project addresses critical security concerns when using Cloudflare as a reverse proxy. By automating the management of trusted proxies and enforcing strict SSL configurations, it ensures that your server remains secure against common threats such as IP spoofing and unauthorized access. The use of Docker simplifies deployment and maintenance, making it an ideal solution for production environments.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details