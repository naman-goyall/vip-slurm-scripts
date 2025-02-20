#!/bin/bash
#SBATCH --job-name=magicprompt_gpu        # Job name
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --gres=gpu:A100:1                # Request 1 A100 GPU
#SBATCH --cpus-per-task=8                # CPUs per task (for GPU support)
#SBATCH --mem=32GB                       # Memory per node
#SBATCH --time=00:30:00                  # Walltime
#SBATCH --output=magicprompt_gpu_%j.txt  # Output file
#SBATCH --partition=gpu                   # GPU partition

# Load required modules for GT ICE
module load cuda/12.1.1
module load gcc/12.3.0
module load cmake/3.26.3

# Set working directory
export WORKDIR=$HOME/magicprompt_inference
mkdir -p $WORKDIR
cd $WORKDIR

# Clone llama.cpp if not present
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git
fi

cd llama.cpp

# Build with CUDA support
mkdir -p build && cd build
cmake .. -DLLAMA_CUBLAS=ON
make -j$(nproc)

cd ..

# Create models directory
mkdir -p models
cd models

# Download model if not present
MODEL_URL="https://huggingface.co/tensorblock/MagicPrompt-Stable-Diffusion-GGUF/resolve/main/magicprompt.Q4_0.gguf"
MODEL_NAME="magicprompt.Q4_0.gguf"

if [ ! -f "$MODEL_NAME" ]; then
    wget $MODEL_URL -O $MODEL_NAME
fi

cd ..

# Set CUDA visible devices
export CUDA_VISIBLE_DEVICES=0

# Run inference with GPU acceleration
./bin/llama -m models/$MODEL_NAME \
    -ngl 1 \
    --n-gpu-layers 1 \
    -p "Generate an imaginative and surreal artistic prompt for Stable Diffusion." \
    --gpu-layers 99999


