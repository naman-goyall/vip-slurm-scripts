#!/bin/bash
#SBATCH --job-name=magicprompt_inference   # Job name
#SBATCH --nodes=1                          # Number of nodes
#SBATCH --ntasks=1                         # Number of tasks (processes)
#SBATCH --cpus-per-task=4                  # Number of CPUs per task
#SBATCH --mem=8GB                          # Memory per node
#SBATCH --time=00:30:00                    # Walltime (hh:mm:ss)
#SBATCH --output=magicprompt_output_%j.txt # Output file (%j expands to jobID)

# Load necessary modules
module load gcc/12.3.0                      # Load GCC compiler module
module load cmake/3.30.2                     # Load the correct CMake version

# Set working directory
export WORKDIR=$HOME/magicprompt_inference
mkdir -p $WORKDIR
cd $WORKDIR

# Clone the llama.cpp repository if not already present
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git
fi

# Navigate to the llama.cpp directory
cd llama.cpp

# Build the project using CMake (since Makefile is deprecated)
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# Move back to llama.cpp directory
cd ..

# Create a directory for models if it doesn't exist
mkdir -p models
cd models

# **Corrected Model URL**: Check the actual Hugging Face model page for the right URL
MODEL_URL="https://huggingface.co/tensorblock/MagicPrompt-Stable-Diffusion-GGUF/resolve/main/magicprompt.Q4_0.gguf"
MODEL_NAME="magicprompt.Q4_0.gguf"

# Download the model if it doesn't exist
if [ ! -f "$MODEL_NAME" ]; then
    wget $MODEL_URL -O $MODEL_NAME
fi

# Navigate back to the main llama.cpp directory
cd ..

# Run the model with a sample input prompt (using correct binary name)
./bin/llama -m models/$MODEL_NAME -p "Generate an imaginative and surreal artistic prompt for Stable Diffusion."



