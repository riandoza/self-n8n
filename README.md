# n8n Docker Self-Hosting Setup

A comprehensive, production-ready Docker setup for self-hosting n8n with PostgreSQL, Nginx reverse proxy, automated backups, monitoring, and security hardening.

## 🚀 Quick Start

1. **Clone or download this setup**
2. **Run the setup script:**

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Choose "Quick Start" for local development**
4. **Access n8n at:** http://localhost:5678

## 📋 Features

- **Production-ready** PostgreSQL database
- **Nginx reverse proxy** with SSL support
- **Automated backups** with retention management
- **Comprehensive monitoring** and health checks
- **Security hardening** with access controls
- **Volume persistence** for data and workflows
- **Easy management** with interactive scripts

## 🏗️ Architecture

```
Internet → Nginx (SSL) → n8n Application → PostgreSQL Database
```

- **Port 80/443:** HTTP/HTTPS via Nginx
- **Port 5678:** n8n application (localhost only)
- **Port 5432:** PostgreSQL (internal only)

## 📁 Directory Structure

```
n8n-docker-setup/
├── docker-compose.yml              # Main Docker Compose configuration
├── .env.example                    # Environment template
├── setup.sh                       # Master setup script
├── manage.sh                       # Management interface
├── data/                          # Persistent data
│   ├── n8n/                      # n8n application data
│   └── postgres/                  # PostgreSQL data
├── nginx/                         # Nginx configuration
│   └── nginx.conf                 # Reverse proxy config
├── ssl/                          # SSL certificates
├── logs/                         # Application logs
├── backup/                       # Automated backups
└── scripts/                      # Management scripts
    ├── generate-keys.sh          # Security key generation
    ├── setup-volumes.sh          # Volume configuration
    ├── setup-ssl.sh              # SSL certificate setup
    ├── health-check.sh           # Health monitoring
    ├── backup.sh                 # Backup management
    └── init-db.sql               # Database initialization
```

Note: rename `.env.example` into `.env`

## 🔧 Management

Use the interactive management script:

```bash
./manage.sh
```

### Quick Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Health check
./scripts/health-check.sh

# Create backup
./scripts/backup.sh

# Generate new keys
./scripts/generate-keys.sh
```

## 🔐 Security Features

- **Basic authentication** with generated passwords
- **Encryption keys** for data protection
- **SSL/TLS termination** at reverse proxy
- **Security headers** for web protection
- **Rate limiting** for API endpoints
- **Docker socket** read-only mounting

## 💾 Backup & Restore

### Automated Backups

- **Configurable retention** (default: 30 days)
- **Integrity verification** with checksums
- **Compressed storage** for efficiency

### Manual Backup

```bash
./scripts/backup.sh full          # Complete backup
./scripts/backup.sh database      # Database only
```

## 📊 Monitoring

### Health Checks

```bash
./scripts/health-check.sh check   # One-time check
./scripts/health-check.sh monitor # Continuous monitoring
```

## 🔧 Customization

### Environment Variables

Edit `.env` file or use:

```bash
./manage.sh  # Option 8: Edit environment
```

### SSL Certificates

```bash
# Self-signed (development)
./scripts/setup-ssl.sh localhost

# Let's Encrypt (production)
./scripts/setup-ssl.sh yourdomain.com
```

## 🚀 Production Deployment

1. **Run production setup:**

   ```bash
   ./setup.sh
   # Choose "Production Setup"
   ```

2. **Enter your domain name**

3. **Configure DNS** to point to your server

4. **SSL certificates** will be automatically generated

## 🔍 Troubleshooting

### Common Issues

**Container won't start:**

```bash
# Check logs
docker-compose logs [service-name]

# Check permissions
sudo chown -R 1000:1000 ./data/n8n
```

**Database connection issues:**

```bash
# Verify database is running
docker exec n8n_postgres pg_isready -U n8n_user

# Check database logs
docker-compose logs postgres
```

## 📋 System Requirements

- **OS:** Ubuntu 20.04+ / CentOS 8+ / Docker-compatible OS
- **Memory:** 2GB RAM minimum (4GB recommended)
- **Storage:** 10GB available space
- **Network:** Internet connection for Docker images and webhooks
- **Software:** Docker 20.10+ and Docker Compose 1.29+

## 🔄 Updates

```bash
# Update container images
./manage.sh  # Option 6: Update containers

# Or manually:
docker-compose pull
docker-compose up -d
```

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🆘 Support

For issues with this setup:

1. Check the troubleshooting section
2. Review logs using `./manage.sh`
3. Consult n8n community forums

## 📄 License

This setup is provided as-is for educational and production use. Please ensure compliance with n8n's licensing terms for your use case.
