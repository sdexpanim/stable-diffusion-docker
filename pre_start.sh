#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "Container is running"

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au /venv/ /workspace/venv/
rm -rf /venv

# Sync Web UI to workspace to support Network volumes
echo "Syncing Stable Diffusion Web UI to workspace, please wait..."
rsync -au /stable-diffusion-webui/ /workspace/stable-diffusion-webui/
rm -rf /stable-diffusion-webui

# Sync Kohya_ss to workspace to support Network volumes
echo "Syncing Kohya_ss to workspace, please wait..."
rsync -au /kohya_ss/ /workspace/kohya_ss/
rm -rf /kohya_ss

# Sync ComfyUI to workspace to support Network volumes
echo "Syncing ComfyUI to workspace, please wait..."
rsync -au /ComfyUI/ /workspace/ComfyUI/
rm -rf /ComfyUI

#install models
if [[ ! -d "/sd-models" ]]
then
    mkdir /sd-models
    #AnimateDiff custom models
    git clone https://huggingface.co/manshoety/AD_Stabilized_Motion
    mv -t /workspace/ComfyUI/custom_nodes/ComfyUI-AnimateDiff-Evolved/models AD_Stabilized_Motion/mm-Stabilized_high.pth AD_Stabilized_Motion/mm-Stabilized_mid.pth 
    rm -rf AD_Stabilized_Motion
    #SD 1.5 models
    mkdir tempmodels
    wget "https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16" --content-disposition -P /sd-models
    wget "https://civitai.com/api/download/models/46846" --content-disposition -P /sd-models
    wget "https://civitai.com/api/download/models/157159?type=Model&format=SafeTensor&size=full&fp=fp16" --content-disposition -P /sd-models
    wget "https://civitai.com/api/download/models/130072?type=Model&format=SafeTensor&size=pruned&fp=fp16" --content-disposition -P /sd-models
    #SDXL models
    wget "https://civitai.com/api/download/models/148259" --content-disposition -P /sd-models
    wget "https://civitai.com/api/download/models/156005" --content-disposition -P /sd-models
    wget "https://civitai.com/api/download/models/151901" --content-disposition -P /sd-models
    wget "https://civitai.com/api/download/models/144229" --content-disposition -P /sd-models
    #VAEs
    wget "https://huggingface.co/WarriorMama777/OrangeMixs/blob/main/VAEs/orangemix.vae.pt" -P /sd-models
    wget https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors -P /sd-models
    wget wget https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors -P /sd-models
    #Embeddings
    wget "https://huggingface.co/embed/bad_prompt/blob/main/bad_prompt_version2.pt" -P /sd-models
    wget "https://huggingface.co/nick-x-hacker/bad-artist/blob/main/bad-artist.pt" -P /sd-models
fi


# Sync Application Manager to workspace to support Network volumes
echo "Syncing Application Manager to workspace, please wait..."
rsync -au /app-manager/ /workspace/app-manager/
rm -rf /app-manager

# Fix the venvs to make them work from /workspace
echo "Fixing Stable Diffusion Web UI venv..."
/fix_venv.sh /venv /workspace/venv

# echo "Fixing Kohya_ss venv..."
# /fix_venv.sh /kohya_ss/venv /workspace/kohya_ss/venv

echo "Fixing ComfyUI venv..."
/fix_venv.sh /ComfyUI/venv /workspace/ComfyUI/venv

# Link modelS and VAE
#SD 1.5
ln -s /sd-models/dreamshaper_8.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/dreamshaper_8.safetensors
ln -s /sd-models/revAnimated_v122EOL.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/revAnimated_v122EOL.safetensors
ln -s /sd-models/realcartoon3d_v7.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/realcartoon3d_v7.safetensors
ln -s /sd-models/realisticVisionV51_v51VAE.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/realisticVisionV51_v51VAE.safetensors
#SDXL
ln -s /sd-models/dynavisionXLAllInOneStylized_beta0411Bakedvae.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/dynavisionXLAllInOneStylized_beta0411Bakedvae.safetensors
ln -s /sd-models/juggernautXL_version3.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/juggernautXL_version3.safetensors
ln -s /sd-models/nightvisionXLPhotorealisticPortrait_beta0702Bakedvae.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/nightvisionXLPhotorealisticPortrait_beta0702Bakedvae.safetensors
ln -s /sd-models/protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors
#VAE
ln -s /sd-models/orangemix.vae.pt workspace/stable-diffusion-webui/models/VAE/orangemix.vae.pt
ln -s /sd-models/vae-ft-mse-840000-ema-pruned.safetensors workspace/stable-diffusion-webui/models/VAE/vae-ft-mse-840000-ema-pruned.safetensors
ln -s /sd-models/sdxl_vae.safetensors /workspace/stable-diffusion-webui/models/VAE/sdxl_vae.safetensors
#Emeddings
ln -s /sd-models/bad_prompt_version2.pt workspace/stable-diffusion-webui/embeddings/bad_prompt_version2.pt
ln -s /sd-models/bad-artist.pt workspace/stable-diffusion-webui/embeddings/bad-artist.pt

# Configure accelerate
echo "Configuring accelerate..."
mkdir -p /root/.cache/huggingface/accelerate
mv /accelerate.yaml /root/.cache/huggingface/accelerate/default_config.yaml

# Create logs directory
mkdir -p /workspace/logs

# Start application manager
cd /workspace/app-manager
npm start > /workspace/logs/app-manager.log 2>&1 &

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the applications will not be started automatically"
    echo "You can launch them manually using the launcher scripts:"
    echo ""
    echo "   Stable Diffusion Web UI:"
    echo "   ---------------------------------------------"
    echo "   cd /workspace/stable-diffusion-webui"
    echo "   deactivate && source /workspace/venv/bin/activate"
    echo "   ./webui.sh -f"
    echo ""
    echo "   Kohya_ss"
    echo "   ---------------------------------------------"
    echo "   cd /workspace/kohya_ss"
    echo "   deactivate"
    echo "   ./gui.sh --listen 0.0.0.0 --server_port 3011 --headless"
    echo ""
    echo "   ComfyUI"
    echo "   ---------------------------------------------"
    echo "   cd /workspace/ComfyUI"
    echo "   deactivate"
    echo "   source venv/bin/activate"
    echo "   python3 main.py --listen 0.0.0.0 --port 3021"
else
    echo "Starting Stable Diffusion Web UI"
    cd /workspace/stable-diffusion-webui
    nohup ./webui.sh -f > /workspace/logs/webui.log 2>&1 &
    echo "Stable Diffusion Web UI started"
    echo "Log file: /workspace/logs/webui.log"

    echo "Starting Kohya_ss Web UI"
    cd /workspace/kohya_ss
    nohup ./gui.sh --listen 0.0.0.0 --server_port 3011 --headless > /workspace/logs/kohya_ss.log 2>&1 &
    echo "Kohya_ss started"
    echo "Log file: /workspace/logs/kohya_ss.log"

    echo "Starting ComfyUI"
    cd /workspace/ComfyUI
    source venv/bin/activate
    python3 main.py --listen 0.0.0.0 --port 3021 > /workspace/logs/comfyui.log 2>&1 &
    echo "ComfyUI started"
    echo "Log file: /workspace/logs/comfyui.log"
    deactivate
fi

if [ ${ENABLE_TENSORBOARD} ];
then
    echo "Starting Tensorboard"
    cd /workspace
    mkdir -p /workspace/logs/ti
    mkdir -p /workspace/logs/dreambooth
    ln -s /workspace/stable-diffusion-webui/models/dreambooth /workspace/logs/dreambooth
    ln -s /workspace/stable-diffusion-webui/textual_inversion /workspace/logs/ti
    source /workspace/venv/bin/activate
    nohup tensorboard --logdir=/workspace/logs --port=6066 --host=0.0.0.0 > /workspace/logs/tensorboard.log 2>&1 &
    deactivate
    echo "Tensorboard Started"
fi

echo "All services have been started"
