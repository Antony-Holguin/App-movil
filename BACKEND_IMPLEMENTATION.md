# Backend Implementation Guide

Esta guía te ayudará a implementar el backend necesario para la aplicación de gestión de videos según los requerimientos especificados.

## 🏗️ Arquitectura del Backend

### Componentes Principales
- **API Gateway/Load Balancer** (Nginx como proxy reverso)
- **Servicio de Videos** (Python + Flask)
- **Servicio de Publicación** (Python + Flask)
- **Base de Datos** (AWS RDS - PostgreSQL/MySQL)
- **Almacenamiento** (AWS S3)

## 📋 Requerimientos Técnicos

### Infraestructura AWS
- **EC2**: Instancias para servicios backend
- **RDS**: Base de datos relacional
- **S3**: Almacenamiento de videos y thumbnails
- **VPC**: Red privada virtual
- **Security Groups**: Control de acceso
- **Certificate Manager**: Certificados SSL/TLS

### Tecnologías Recomendadas
- **Python 3.9+** con Flask
- **Docker** para containerización
- **Nginx** como proxy reverso
- **PostgreSQL** como base de datos
- **AWS SDK (boto3)** para integración con servicios AWS

## 🗄️ Estructura de Base de Datos

### Tabla `videos`
```sql
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_path VARCHAR(500),
    s3_url VARCHAR(500) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    thumbnail_path VARCHAR(500),
    thumbnail_s3_key VARCHAR(500),
    tags JSON,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duration INTEGER DEFAULT 0,
    file_size BIGINT DEFAULT 0,
    content_type VARCHAR(100),
    is_published BOOLEAN DEFAULT FALSE,
    published_platforms JSON DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Tabla `publications` (Opcional)
```sql
CREATE TABLE publications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL,
    platform_post_id VARCHAR(255),
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending'
);
```

## 🐳 Implementación con Docker

### 1. Servicio de Videos

**Dockerfile**
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

**requirements.txt**
```txt
Flask==2.3.3
Flask-CORS==4.0.0
boto3==1.28.57
psycopg2-binary==2.9.7
python-decouple==3.8
Pillow==10.0.0
gunicorn==21.2.0
requests==2.31.0
```

**app.py** (Servicio de Videos)
```python
import os
import uuid
import json
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import boto3
import psycopg2
from werkzeug.utils import secure_filename
from decouple import config

app = Flask(__name__)
CORS(app)

# Configuración AWS
AWS_ACCESS_KEY_ID = config('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = config('AWS_SECRET_ACCESS_KEY')
AWS_REGION = config('AWS_REGION', default='us-east-1')
S3_BUCKET_NAME = config('S3_BUCKET_NAME')

# Configuración Base de Datos
DB_HOST = config('DB_HOST')
DB_NAME = config('DB_NAME')
DB_USER = config('DB_USER')
DB_PASSWORD = config('DB_PASSWORD')
DB_PORT = config('DB_PORT', default=5432)

# Clientes AWS
s3_client = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_REGION
)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )

@app.route('/api/videos', methods=['GET'])
def get_videos():
    try:
        search = request.args.get('search', '')
        sort_by = request.args.get('sort_by', 'date')
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        query = """
            SELECT id, title, description, s3_url, thumbnail_path, tags, 
                   upload_date, duration, is_published, published_platforms
            FROM videos
        """
        params = []
        
        if search:
            query += " WHERE title ILIKE %s OR description ILIKE %s OR tags::text ILIKE %s"
            search_param = f'%{search}%'
            params.extend([search_param, search_param, search_param])
        
        if sort_by == 'title':
            query += " ORDER BY title ASC"
        else:
            query += " ORDER BY upload_date DESC"
        
        cur.execute(query, params)
        videos = cur.fetchall()
        
        result = []
        for video in videos:
            result.append({
                'id': str(video[0]),
                'title': video[1],
                'description': video[2] or '',
                'file_path': video[3] or '',
                's3_url': video[3],
                'thumbnail_path': video[4] or '',
                'tags': video[5] or [],
                'upload_date': video[6].isoformat(),
                'duration': video[7],
                'is_published': video[8],
                'published_platforms': video[9] or []
            })
        
        cur.close()
        conn.close()
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/videos/upload', methods=['POST'])
def upload_video():
    try:
        if 'video' not in request.files:
            return jsonify({'error': 'No video file provided'}), 400
        
        video_file = request.files['video']
        title = request.form.get('title', '')
        description = request.form.get('description', '')
        tags = json.loads(request.form.get('tags', '[]'))
        
        if not title:
            return jsonify({'error': 'Title is required'}), 400
        
        # Generar nombre único para el archivo
        video_id = str(uuid.uuid4())
        file_extension = video_file.filename.split('.')[-1]
        s3_key = f'videos/{video_id}.{file_extension}'
        
        # Subir a S3
        s3_client.upload_fileobj(
            video_file,
            S3_BUCKET_NAME,
            s3_key,
            ExtraArgs={'ContentType': video_file.content_type}
        )
        
        s3_url = f'https://{S3_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{s3_key}'
        
        # Guardar en base de datos
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute("""
            INSERT INTO videos (id, title, description, s3_url, s3_key, tags, content_type)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """, (video_id, title, description, s3_url, s3_key, json.dumps(tags), video_file.content_type))
        
        video = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            'id': str(video[0]),
            'title': video[1],
            'description': video[2] or '',
            'file_path': '',
            's3_url': video[4],
            'thumbnail_path': video[6] or '',
            'tags': json.loads(video[7]) if video[7] else [],
            'upload_date': video[8].isoformat(),
            'duration': video[9],
            'is_published': video[12],
            'published_platforms': json.loads(video[13]) if video[13] else []
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/videos/<video_id>', methods=['DELETE'])
def delete_video(video_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Obtener información del video para eliminar de S3
        cur.execute("SELECT s3_key FROM videos WHERE id = %s", (video_id,))
        video = cur.fetchone()
        
        if not video:
            return jsonify({'error': 'Video not found'}), 404
        
        # Eliminar de S3
        s3_client.delete_object(Bucket=S3_BUCKET_NAME, Key=video[0])
        
        # Eliminar de base de datos
        cur.execute("DELETE FROM videos WHERE id = %s", (video_id,))
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Video deleted successfully'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0')
```

### 2. Servicio de Publicación

**publish_service.py**
```python
import os
import json
import requests
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from decouple import config

app = Flask(__name__)
CORS(app)

# Configuración Base de Datos (misma que servicio de videos)
DB_HOST = config('DB_HOST')
DB_NAME = config('DB_NAME')
DB_USER = config('DB_USER')
DB_PASSWORD = config('DB_PASSWORD')
DB_PORT = config('DB_PORT', default=5432)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )

@app.route('/api/videos/<video_id>/publish', methods=['POST'])
def publish_video(video_id):
    try:
        data = request.json
        platforms = data.get('platforms', [])
        
        if not platforms:
            return jsonify({'error': 'No platforms specified'}), 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Obtener información del video
        cur.execute("SELECT * FROM videos WHERE id = %s", (video_id,))
        video = cur.fetchone()
        
        if not video:
            return jsonify({'error': 'Video not found'}), 404
        
        published_platforms = json.loads(video[13]) if video[13] else []
        
        # Simular publicación en cada plataforma
        for platform in platforms:
            if platform not in published_platforms:
                # Aquí implementarías la lógica específica para cada plataforma
                success = publish_to_platform(platform, video)
                if success:
                    published_platforms.append(platform)
        
        # Actualizar estado de publicación
        cur.execute("""
            UPDATE videos 
            SET is_published = %s, published_platforms = %s, updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
        """, (len(published_platforms) > 0, json.dumps(published_platforms), video_id))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'Video published successfully'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def publish_to_platform(platform, video):
    """
    Implementa la lógica específica para publicar en cada plataforma.
    Aquí debes integrar con las APIs de las redes sociales.
    """
    # Simulación - en producción conectarías con APIs reales
    print(f"Publishing video {video[0]} to {platform}")
    
    # Ejemplo para diferentes plataformas:
    if platform == 'facebook':
        return publish_to_facebook(video)
    elif platform == 'youtube':
        return publish_to_youtube(video)
    elif platform == 'instagram':
        return publish_to_instagram(video)
    # ... otros casos
    
    return True  # Simulación exitosa

def publish_to_facebook(video):
    # Implementar API de Facebook
    return True

def publish_to_youtube(video):
    # Implementar API de YouTube
    return True

def publish_to_instagram(video):
    # Implementar API de Instagram
    return True

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5001)
```

### 3. Docker Compose

**docker-compose.yml**
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - video-service
      - publish-service
    networks:
      - app-network

  video-service:
    build: ./video-service
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION}
      - S3_BUCKET_NAME=${S3_BUCKET_NAME}
      - DB_HOST=${DB_HOST}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    networks:
      - app-network

  publish-service:
    build: ./publish-service
    environment:
      - DB_HOST=${DB_HOST}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

### 4. Configuración Nginx

**nginx.conf**
```nginx
events {
    worker_connections 1024;
}

http {
    upstream video_service {
        server video-service:5000;
    }
    
    upstream publish_service {
        server publish-service:5001;
    }

    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        client_max_body_size 100M;

        location /api/videos {
            proxy_pass http://video_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /api/videos/ {
            if ($request_uri ~ "^/api/videos/[^/]+/publish") {
                proxy_pass http://publish_service;
            }
            proxy_pass http://video_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

## 🚀 Pasos de Implementación

### 1. Configuración AWS

```bash
# Crear S3 Bucket
aws s3 mb s3://your-video-bucket-name --region us-east-1

# Configurar CORS para S3
aws s3api put-bucket-cors --bucket your-video-bucket-name --cors-configuration file://cors.json
```

**cors.json**
```json
{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
            "AllowedHeaders": ["*"],
            "MaxAgeSeconds": 3000
        }
    ]
}
```

### 2. Configurar RDS

```bash
# Crear instancia RDS PostgreSQL
aws rds create-db-instance \
    --db-instance-identifier video-app-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --master-username admin \
    --master-user-password your-password \
    --allocated-storage 20 \
    --vpc-security-group-ids sg-xxxxxxxxx
```

### 3. Configurar EC2

```bash
# Instalar Docker y Docker Compose en EC2
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 4. Variables de Entorno

Crear archivo **.env**
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
S3_BUCKET_NAME=your-video-bucket-name
DB_HOST=your-rds-endpoint
DB_NAME=video_app
DB_USER=admin
DB_PASSWORD=your_password
DB_PORT=5432
```

### 5. Deploy

```bash
# Clonar repositorio y navegar al directorio
git clone your-backend-repo
cd your-backend-repo

# Construir y ejecutar contenedores
docker-compose up -d --build

# Verificar que servicios estén corriendo
docker-compose ps
```

## 🔐 Seguridad

### Security Groups
- **Puerto 80/443**: Acceso HTTP/HTTPS desde internet
- **Puerto 5432**: Base de datos accesible solo desde VPC
- **Puertos internos**: Solo comunicación entre servicios

### Variables de Entorno
- Nunca hardcodear credenciales
- Usar AWS Secrets Manager para producción
- Rotar claves regularmente

### SSL/TLS
- Usar certificados válidos (Let's Encrypt o AWS Certificate Manager)
- Configurar HTTPS para todas las comunicaciones

## 📊 Monitoreo

### CloudWatch
- Configurar logs de aplicación
- Métricas de performance
- Alertas por errores

### Health Checks
```python
@app.route('/health')
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})
```

## 🧪 Testing

### Tests Unitarios
```bash
pytest tests/
```

### Tests de Integración
```bash
# Test endpoints con datos reales
curl -X GET https://your-domain.com/api/videos
```

## 📝 Documentación API

### Endpoints Principales

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/videos` | Listar videos |
| POST | `/api/videos/upload` | Subir video |
| DELETE | `/api/videos/{id}` | Eliminar video |
| POST | `/api/videos/{id}/publish` | Publicar video |

Esta implementación proporciona una base sólida para el backend de tu aplicación de gestión de videos, siguiendo las mejores prácticas de seguridad y escalabilidad en AWS.