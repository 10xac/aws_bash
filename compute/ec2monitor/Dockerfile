FROM python:3.10

RUN pip install --upgrade pip

WORKDIR /app

COPY requirements.txt ./requirements.txt
RUN pip install -r ./requirements.txt


###copy all files in currrent dir to WORKDIR/
COPY . .

RUN chmod +x /app/ec2monitor.py

ENV STRAPI_STAGE="dev"

EXPOSE 6000

# CMD ["/app/ec2monitor.py"]
# ENTRYPOINT ["python3"]

#CMD ["sh", "-c", "echo Starting ec2monitor && /app/ec2monitor.py"]
CMD ["python3", "-u", "ec2monitor.py"]

