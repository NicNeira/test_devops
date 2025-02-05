# test_devops

El código dentro de `/app/server.js` crea un servidor web sencillo con Node.js y Express que expone un endpoint `/api/insurance`. Este endpoint realiza una petición a la API externa `https://dn8mlk7hdujby.cloudfront.net/interview/insurance/58` para obtener información sobre un seguro y la devuelve al cliente en formato JSON.

- Endpoint del backend funcionando en el EC2: `http://3.239.248.172:3000/api/insurance`
- La respuesta json que se obtiene es la siguiente:
```JSON
{
  "insurance": {
    "name": "Seguro Vida Activa",
    "description": "Con nuestro Seguro Vida Activa podrás disfrutar el día a día con tranquilidad, gracias al respaldo y apoyo frente a las consecuencias de eventuales accidentes que puedas sufrir. Posee excelente cobertura, un precio muy conveniente y, en caso de fallecimiento, apoyo financiero para tus seres queridos con un capital asegurado.",
    "price": "9000",
    "image": "https://ventaenlinea.bicevida.cl/pub/media/catalog/product/cache/69eb2560c3d44c78f7327201dc5a282b/i/m/img-01.jpg"
  }
}
```

## IaC ( Terraform - AWS )


## Pipeline
Este pipeline automatiza la integración continua y el despliegue continuo de la aplicación. Cada vez que se realiza un push a la rama main, se obtiene el codigo, se realizan test, se construye la imagen Docker, se sube a ECR y se despliega en una instancia EC2, asegurando que la aplicación en producción esté siempre actualizada con los últimos cambios.  El uso de secretos de GitHub protege información sensible como las credenciales de AWS y la clave privada SSH.

Job: `build-and-deploy`


### Steps

- `Checkout code`: Utiliza la acción actions/checkout@v4 para descargar el código del repositorio al runner. Esto es esencial para que los pasos posteriores puedan acceder a los archivos del proyecto.

- `Setup Node and run tests`: Utiliza la acción actions/setup-node@v4 para configurar el entorno de Node.js en el runner. Especifica la versión 20.17.x.

- `Configure AWS credentials`: Utiliza la acción `aws-actions/configure-aws-credentials@v2`para configurar las credenciales de AWS en el runner. Estas credenciales se almacenan como `secrets` en GitHub y se inyectan de forma segura en el entorno del workflow. Se usan las variables de entorno `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_DEFAULT_REGION`.

- `Login to Amazon ECR`: Utiliza la acción `aws-actions/amazon-ecr-login@v2` para autenticar el runner con Amazon Elastic Container Registry (ECR). Esto permite que el runner pueda subir la imagen Docker construida.

- `Build Docker image`: Construye la imagen Docker de la aplicación. Utiliza el comando docker build y etiqueta la imagen con la URL del repositorio ECR `(${{ secrets.ECR_REPOSITORY_URL }})` y la etiqueta latest.

- `Push Docker image`: Sube la imagen Docker construida al repositorio ECR. Primero, se etiqueta la imagen localmente con la misma URL y etiqueta, y luego se usa docker push para subirla.

- `Deploy to EC2`:Este paso realiza el despliegue en la instancia EC2.
  - Se define la variable de entorno `SSH_PRIVATE_KEY` con la clave privada SSH (también almacenada como secreto en GitHub).
  - Se utiliza ssh para conectar a la instancia EC2 `(ec2-user@${{ secrets.EC2_PUBLIC_IP }})`.
  - Dentro del comando SSH, se ejecutan las siguientes acciones en la instancia EC2:
    - Se agrega el usuario `ec2-user` al grupo docker y se recargan los grupos para que los cambios surtan efecto. Esto permite que el usuario ejecute comandos de Docker sin sudo.
    - Se autentica con ECR usando `aws ecr get-login-password`.
    - Se detienen y eliminan los contenedores Docker existentes (si los hay) para asegurar una actualización limpia.
    - Se descarga la nueva imagen Docker desde ECR usando `docker pull`.
    - Se ejecuta la nueva imagen Docker en un contenedor, mapeando el puerto 3000 del contenedor al puerto 3000 de la instancia EC2 (`-p 3000:3000`). El flag `-d` ejecuta el contenedor en segundo plano (`detached mode`).
