# Sistema Inteligente de Asistencia de Emergencia Vehicular

Proyecto full stack para entrega universitaria con:

- Backend en FastAPI
- Frontend web en Angular para taller, operadores y administración
- App móvil en Flutter para clientes
- Base de datos PostgreSQL
- SQLAlchemy Async, Alembic y JWT
- Docker y configuración inicial para despliegue

## Seguridad y permisos

- JWT con carga de roles
- Endpoint `GET /auth/me` para perfil autenticado
- Registro público limitado al rol `CLIENTE`
- Control de acceso por rol en clientes, técnicos, vehículos, solicitudes y notificaciones
- Restricción por propiedad para que cliente y técnico solo accedan a sus propios recursos

## Arquitectura

```text
backend/   API, modelos, migraciones, seed y autenticación
frontend/  Panel web Angular para gestión operativa
mobile/    App Flutter para clientes
```

## Casos de uso implementados

1. Registro de cliente
2. Inicio de sesión
3. Recuperación de contraseña
4. Edición de perfil
5. Registro de vehículo
6. Edición de vehículo
7. Solicitud de asistencia
8. Envío de ubicación GPS
9. Selección de tipo de avería
10. Envío de foto del incidente
11. Consulta del estado de la solicitud
12. Notificaciones push
13. Historial de asistencias
14. Ver técnicos cercanos
15. Ver solicitudes activas desde la web
16. Asignar técnico
17. Actualizar estado de solicitud
18. Gestionar técnicos
19. Gestionar clientes
20. Cerrar caso
21. Priorización inteligente del incidente
22. Cierre técnico del servicio (trabajo realizado + costo final en Bs)
23. Pago final del cliente (confirmación de pago) y cierre automático a `COMPLETADA`
24. Factura PDF por solicitud (descarga desde web y app móvil)
25. Sección web "Trabajos realizados" con resumen y exportación PDF/CSV
26. Transcripción automática de audio del cliente y notificación a OPERADOR/ADMIN
27. App móvil: ver factura PDF directamente (descarga y apertura)
28. App móvil: grabación y envío de nota de voz desde la solicitud

## Requisitos previos

- Python 3.11+
- Node.js 22+ o Node 18+
- npm 10+
- PostgreSQL 15
- Flutter SDK 3.22+ para compilar la app móvil y generar APK
- Docker Desktop opcional para levantar backend y base de datos por contenedores

## Variables de entorno

Archivo base: [backend/.env.example](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/backend/.env.example)

Variables usadas:

- `DATABASE_URL`
- `SECRET_KEY`
- `ALGORITHM`
- `ACCESS_TOKEN_EXPIRE_MINUTES`
- `CORS_ORIGINS`
- `APP_ENV`
- `BACKEND_BASE_URL`
- `MAPS_API_KEY`
- `FIREBASE_CREDENTIALS`
- `FCM_PROJECT_ID`

## Configuración local

### 1. Backend

```bash
cd backend
python -m pip install -r requirements.txt
```

Configura `backend/.env` con PostgreSQL local:

```env
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/emergency_db
SECRET_KEY=dev-secret-key-no-usar-en-produccion
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
CORS_ORIGINS=["http://localhost:4200","http://localhost:3000","http://localhost:8080"]
APP_ENV=development
BACKEND_BASE_URL=http://localhost:8000
MAPS_API_KEY=demo-maps-key
FIREBASE_CREDENTIALS=
FCM_PROJECT_ID=demo-project-id
```

### 2. Crear base de datos

```sql
CREATE DATABASE emergency_db;
```

### 3. Ejecutar migraciones

```bash
cd backend
python -m alembic -c alembic.ini upgrade head
```

### 4. Cargar datos de prueba

```bash
cd backend
python seed.py
```

Credenciales sugeridas después del seed:

- `admin@emergency.com / Password123*`
- `operador@emergency.com / Password123*`
- `tecnico@emergency.com / Password123*`
- `cliente@emergency.com / Password123*`

### 5. Iniciar backend

```bash
cd backend
python -m uvicorn app.main:app --reload
```

Endpoints útiles:

- Swagger: `http://localhost:8000/docs`
- Health: `http://localhost:8000/health`

## Frontend Angular

Instalación:

```bash
cd frontend
npm install
```

Modo desarrollo:

```bash
npm start
```

Compilación:

```bash
npm run build
```

La web usa `frontend/src/environments/environment.ts` con `http://localhost:8000` como URL base.

Pantallas incluidas:

- login
- dashboard operativo
- solicitudes
- detalle de solicitud
- técnicos
- clientes
- historial
- notificaciones
- perfil

## App móvil Flutter

La carpeta `mobile/` contiene la lógica base de la app cliente con:

- login
- historial
- gestión de vehículos
- creación de solicitud
- geolocalización
- foto del incidente
- mapa
- perfil
- notificaciones
- técnicos cercanos

Instalación de dependencias:

```bash
cd mobile
flutter pub get
```

Si necesitas generar carpetas nativas porque el entorno no las trae todavía:

```bash
cd mobile
flutter create .
flutter pub get
```

Ejecución:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001
```

Generación de APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://emergency-backend-ea41.onrender.com
```

## Docker

Levantar backend + PostgreSQL:

```bash
docker compose up --build
```

Notas:

- `docker-compose.yml` fuerza `DATABASE_URL` apuntando al servicio `db`
- El backend queda expuesto en `http://localhost:8000`
- PostgreSQL queda disponible en `localhost:5432`

## Despliegue rápido

### Backend

- Archivo: [render.yaml](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/backend/render.yaml)
- También puede desplegarse con Railway o cualquier runtime Docker

### Frontend

- Netlify
  - Build: `npm ci && npm run build`
  - Publish: `dist/frontend/browser`
  - Configuración incluida en `frontend/netlify.toml` y `frontend/public/_redirects`
- Vercel
  - Build: `npm ci && npm run build`
  - Output: `dist/frontend/browser` (o `dist/frontend` según la detección del framework)
- Cambiar `apiUrl` del frontend en `frontend/src/environments/environment.prod.ts` al dominio público del backend (Render)
- En backend (Render): configurar CORS para permitir el dominio del frontend (por ejemplo `^https://.*\\.netlify\\.app$` o el dominio exacto)

### Base de datos

- PostgreSQL administrado en Railway, Render o Neon

### App móvil

- Generar APK con `flutter build apk --release`
- Configurar FCM y Google Maps con credenciales reales antes de publicar

## Datos de prueba

Script disponible en [seed.py](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/backend/seed.py).

Incluye:

- 4 usuarios base por rol
- 5 clientes completos
- 3 técnicos operativos en Ciudad de México
- 2 operadores
- 3 talleres
- 10 vehículos
- 20 solicitudes
- tipos de incidente
- estados
- notificaciones e historial

## Módulos principales

### Backend

- [main.py](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/backend/app/main.py)
- [solicitudes.py](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/backend/app/routers/solicitudes.py)
- [prioridad_service.py](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/backend/app/services/prioridad_service.py)
- [001_initial_schema.py](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/backend/alembic/versions/001_initial_schema.py)

### Frontend

- [app.routes.ts](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/frontend/src/app/app.routes.ts)
- [dashboard-page.component.ts](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/frontend/src/app/pages/dashboard-page.component.ts)
- [solicitudes-page.component.ts](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/frontend/src/app/pages/solicitudes-page.component.ts)

### Mobile

- [main.dart](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/mobile/lib/main.dart)
- [home_screen.dart](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/mobile/lib/screens/home_screen.dart)
- [request_screen.dart](file:///c:/Users/ALEXANDER/OneDrive/Escritorio/si2_1erexa/mobile/lib/screens/request_screen.dart)

## Verificación realizada

- Backend importa correctamente
- `pytest` ejecutado sobre el algoritmo de prioridad
- Swagger responde en `/docs`
- Health check responde correctamente
- Angular compila con `npm run build`

## Capturas

Puedes agregar aquí:

- login web
- dashboard web
- gestión de solicitudes
- login móvil
- solicitud de asistencia móvil
- historial móvil

## Autores

- Alexander
- Proyecto académico universitario
