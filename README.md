# Configuración de AWS para Aplicación en ECS

Este repositorio contiene la configuración de recursos de AWS para desplegar una aplicación en un contenedor gestionado por Amazon ECS (Elastic Container Service). Asegúrate de seguir estos pasos para una configuración exitosa.

## Descripción General

El archivo de código proporcionado define varios recursos de AWS que son fundamentales para desplegar una aplicación en contenedores, incluyendo:

- Definición de tarea ECS para el contenedor de la aplicación.
- Configuración de red y seguridad.
- Creación de un Load Balancer (ALB) para la distribución de tráfico.
- Definición del servicio ECS para la administración y ejecución de contenedores.

## Cambio Requerido

Se requiere cambiar la URI de la imagen del contenedor en el recurso `aws_ecs_task_definition` antes de ejecutar este código. Busca la siguiente línea:

```hcl
"image": "244410002174.dkr.ecr.us-east-1.amazonaws.com/segunda-actividad:${var.imagebuild}",

## Configuración de Variables en Azure DevOps

Para el despliegue de infraestructura usando Terraform a través de Azure DevOps, configura las variables correspondientes en la biblioteca de recursos siguiendo estos pasos:

1. **Accede a tu proyecto en Azure DevOps.**
2. **Navega a la sección de Pipelines o Releases y selecciona Library o Biblioteca de Recursos. crea**
3. **Crea un nuevo grupo de variables o utiliza uno existente.**
4. **Añade las siguientes variables para AWS:**
   - `AWS_ACCOUNT_ID`: Identificación de clave de acceso de AWS.
   - `AWS_ECR_REPOSITORY_NAME`: Nombre del repositorio privado ECR.
   - `AWS_REGION`: Región predeterminada de AWS, por ejemplo, `us-east-1`.
   - `AWS_ECR_MAGE_URI`:  URI DEL ECR
   - `AWS_ACCESS_KEY_ID` Key de aws
   - `AWS_SECRET_KEY`: secret key de aws
