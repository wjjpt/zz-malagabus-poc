# zz-gijonbus-poc

Script for query data from Málaga Bus dataset, normalize and inject into kafka topic.
Dataset source: http://datosabiertos.malaga.eu/recursos/transporte/EMT/EMTlineasUbicaciones/lineasyubicaciones.geojson

# BUILDING

- Build docker image:
  * git clone https://github.com/wjjpt/zz-malagabus-poc.git
  * cd src/
  * docker build -t wjjpt/malagabus2k .

# EXECUTING

- Execute app using docker image:

`docker run --env KAFKA_BROKER=X.X.X.X --env KAFKA_PORT=9092 --env KAFKA_TOPIC='malagabus' -ti wjjpt/malagabus2k`

