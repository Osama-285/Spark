FROM openjdk:11-jre-slim

# Install dependencies for Spark, Jupyter, and additional tools
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    procps \
    nano \
    vim \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# Upgrade pip
RUN pip3 install --upgrade pip

# Install JupyterLab, PySpark, and additional libraries
RUN pip3 install \
    jupyterlab \
    pyspark==3.5.3 \
    kafka-python==2.0.2 \
    delta-spark==3.2.0 \
    boto3 \
    pandas \
    pyarrow \
    grpcio \
    protobuf \
    grpcio-status \
    matplotlib

# Define Spark version
ARG SPARK_VERSION=3.5.3
ARG HADOOP_VERSION=3

# Set environment variables for Spark
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-*-src.zip:$PYTHONPATH
ENV PYSPARK_PYTHON=/usr/bin/python3

# Download and install Spark
RUN curl -L "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -o /tmp/spark.tgz && \
    tar -xzf /tmp/spark.tgz -C /opt/ && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} $SPARK_HOME && \
    rm /tmp/spark.tgz

# Download Spark Connect JAR
RUN curl -L "https://repo1.maven.org/maven2/org/apache/spark/spark-connect_2.12/3.5.3/spark-connect_2.12-3.5.3.jar" -o /tmp/spark-connect_2.12-3.5.3.jar && \
    mv /tmp/spark-connect_2.12-3.5.3.jar $SPARK_HOME/jars/

# Fix Spark configuration files
RUN mv $SPARK_HOME/conf/log4j2.properties.template $SPARK_HOME/conf/log4j2.properties && \
    mv $SPARK_HOME/conf/spark-defaults.conf.template $SPARK_HOME/conf/spark-defaults.conf && \
    mv $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh

# Fix Jupyter logging issue
RUN ipython profile create && \
    echo "c.IPKernelApp.capture_fd_output = False" >> "/root/.ipython/profile_default/ipython_kernel_config.py"

# Set working directory for Jupyter notebooks
WORKDIR /opt/notebooks

# Expose ports: 8080 for Spark UI, 8888 for Jupyter, 7077 for Spark Master, 4040 for Spark Application UI
EXPOSE 8880 8888 7077 4040

# Start Spark Master and Worker in the background, then JupyterLab
CMD ["sh", "-c", "start-master.sh & start-worker.sh spark://spark-jupyter:7077 & python3 -m jupyterlab --ip=0.0.0.0 --port=8888 --no-browser --allow-root"]