# easy-diffusion-cli
CLI for Easy-Diffusion

1. Have a running copy of [Easy-Diffusion](https://easydiffusion.github.io/)

2. Use of CLI

   ```bash
   Usage: easy-diffusion-cli.sh --prompt "Your prompt here"

   Optional arguments:
       [--model MODEL]
       [--init-image "/path/to/image"]
       [--seed SEED]
       [--negative-prompt "Negative prompt"]
       [--num-inference-steps STEPS]
       [--guidance-scale SCALE] (Higher the number, more weight to prompt)
       [--prompt-strength STRENGTH] (Lower the number, more weight to init image)
       [--width WIDTH]
       [--height HEIGHT]
       [--save-to-disk-path PATH]
       [--session_id ID]
    ```
3. Examples

### Syntax

```bash
for i in $(stat path/to/*jpg | awk '{print $2}' | grep jpg); \
do bash easy-diffusion-cli.sh --prompt "My awesome prompt" \
  --prompt-strength "0.4" --session_id 1 --num-inference-steps 56 --guidance-scale 8 \
  --save-to-disk-path /home/ubuntu/Pictures/easy-diffusion/ --init-image $i --seed 2555259 \
  --width 768 --height 512;
  sleep 10;
done
```
