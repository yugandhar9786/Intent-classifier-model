FROM python:3.12-slim

# prevent python from generating .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# prevent python from buffering stdout and stderr
ENV PYTHONUNBUFFERED=1

# set working directory
WORKDIR /app

COPY requirements.txt .

# update apt packages and install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && pip install --upgrade pip \
    && pip install -r requirements.txt \
    && apt-get remove -y build-essential \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN python3 model/train.py

EXPOSE 6000

CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:6000", "app:app"]


