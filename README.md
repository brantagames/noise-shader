# Noise Shader

This addon adds **CyclingNoiseEffect**, which is a **CompositorEffect** that can be added to cameras.
The shader takes the brightness output of the camera and adds it to the noise, cycling through the colors.
This creates an image that can only be seen while its playing.

## Usage

All you have to do is add **PostProcessNoise** to your camera's compositor effects.
To make the effect good, the scene's setup needs to work well with the shader.
In the first person demo, I give the player camera an **OmniLight3D**, which makes closer objects brighter.
I also recommend making the sky black, so it doesn't interfere with the noise.

## Parameters and Methods

- **randomize_noise_on_resize** makes it so when the shader is first loaded and the window's size has changed, the noise is randomized
- **steps** is how many different shades the effect displays
- **speed** is how fast the effect is updated
- **randomize_noise** assigns a random value to each pixel
- **clear_noise** resets the value of every pixel
