# DevOps Demo App

This is a simple application designed to demonstrate DevOps practices, specifically focusing on Dockerization and deployment to Azure Container Registry (ACR).

## Project Structure

```
devops-demo-app
├── src
│   └── app.py          # Simple Flask application
├── requirements.txt    # Python dependencies
├── Dockerfile          # Docker image instructions
├── .dockerignore       # Files to ignore in Docker build
├── azure-pipelines.yml # Azure DevOps pipeline configuration
└── README.md           # Project documentation
```

## Getting Started

### Prerequisites

- Python 3.x
- Docker
- Azure CLI
- Azure DevOps account

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd devops-demo-app
   ```

2. Install the required Python packages:
   ```
   pip install -r requirements.txt
   ```

### Running the Application

To run the application locally, execute the following command:
```
python src/app.py
```
The application will be accessible at `http://localhost:5000`.

### Dockerization

To build the Docker image, run:
```
docker build -t devops-demo-app .
```

To run the Docker container, use:
```
docker run -p 5000:5000 devops-demo-app
```

### Azure Pipeline

To set up the Azure DevOps pipeline, ensure you have the `azure-pipelines.yml` configured correctly. This file contains the necessary steps to build and push the Docker image to Azure Container Registry.

1. Create a new pipeline in Azure DevOps and link it to this repository.
2. Run the pipeline to build and push the Docker image to ACR.

## License

This project is licensed under the MIT License - see the LICENSE file for details.