# Noise Shader

This addon adds 3 **CompositorEffect**s that can be added to cameras.
These shaders take the color output of the camera and uses it to adjust their images.
This creates an image that can only be seen while its playing.

## Usage

All you have to do is add one of the three effects (**CyclingNoiseEffect**, **SlidingNoiseEffect**, or **ColorfulNoiseEffect**) to your camera's compositor effects.
To make the effect good, the scene's setup needs to work well with the shader.
In the first person demo, I give the player camera an **OmniLight3D**, which makes closer objects brighter.
I also recommend making the sky black, so it doesn't interfere with the noise.

## The Different Effects

### Cycling Noise

This effect cycles through different shades of white and black to create a cycling image.
The brighter the input pixel, the faster the shader updates.

- **steps** is how many different shades the effect displays
- **speed** is how fast the effect is updated

### Sliding Noise

This effect moves pixels every frame to create a sliding effect.
All moving pixels move at the same exact speed.

- **direction** is the direction the pixels slide
- **invert** controls which part of the image slides
- **frames_per_update** controls how often the sliding updates

### Colorful Noise

Equivalent to the cycling noise, but can cycle color too.
The red channel controls pixel value, and the green channel controls color.

- **value_steps** is how many different brightness levels the effect displays
- **value_speed** is how fast the value of the pixels change
- **hue_steps** is how many different colors the effect displays
- **hue_speed** is how fast the colors of the pixels change
- **hue_offset** adjusts what colors are displayed
