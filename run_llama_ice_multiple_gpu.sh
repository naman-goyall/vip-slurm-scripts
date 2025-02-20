#!/bin/bash
#SBATCH --job-name=magicprompt_multigpu   # Job name
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --gres=gpu:A100:2                # Request 2 A100 GPUs
#SBATCH --cpus-per-task=16               # More CPUs for multi-GPU
#SBATCH --mem=64GB                       # More memory for multi-GPU
#SBATCH --time=00:30:00                  # Walltime
#SBATCH --output=magicprompt_mgpu_%j.txt # Output file
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
cmake .. -DLLAMA_CUBLAS=ON -DLLAMA_CUDA_FORCE_MMQ=ON
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

# Enable both GPUs
export CUDA_VISIBLE_DEVICES=0,1

# Run inference with multi-GPU support
./bin/llama -m models/$MODEL_NAME \
    -ngl 2 \
    --n-gpu-layers 2 \
    --tensor-split 0.5,0.5 \
    -p "Generate an imaginative and surreal artistic prompt for Stable Diffusion." \
    --gpu-layers 99999