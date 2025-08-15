Requerimientos
La aplicación debe estar alojada en la infraestructura de AWS
El código fuente debe estar alojado en GitHub
La aplicación móvil puede estar desarrollada usando el framework de su preferencia
Los servicios del backend pueden ser desarrollados en el lenguaje de programación y framework de su preferencia:
Se recomienda trabajar con Python y Flask
La cada servicio debe estar Dockerizado
Debe utiliza el SDK de AWS para gestionar y consumir los recursos de S3 y RDS
Las claves y credenciales de seguridad no deben estar quemadas en el código (no está permitido el hard-coding)
El backend debe ser accesible para cualquier dispositivo que tenga la app
El bucket de S3 debe almacenar los videos cargados y consumidos por la app
La base de datos RDS puede correr el motor de su preferencia y contener las tablas necesarias para cumplir con los requerimientos dados
El acceso a los servicios en EC2 debe hacerse por HTTPS y debe haber un Proxy reverso
Funciones de la aplicación
La aplicación no requiere login
Carga de videos
La aplicación debe permitir grabar o seleccionar videos de la galería para ser subidos a S3
Se debe almacenar metadatos de estas subidas en RDS
Visualización de videos cargados
El usuario debe poder ver (desde la aplicación) los videos cargados con la información almacenada
La visualización debe permitir ordenar los videos por fecha de carga o por título
La aplicación debe permitir la búsqueda de videos por etiquetas(tags), fecha de carga o título
Publicación de videos
El usuario debe de disponer de un botón “Publicar” que le permita publicar el video seleccionado en al menos dos redes sociales
Esta funcionalidad debe estar implementada en un servicio dedicado como se muestra en el diagrama
