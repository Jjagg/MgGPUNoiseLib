using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GpuNoiseLib {
    public class Perlin2DEffect : FbmEffect {
        public Perlin2DEffect(GraphicsDevice graphicsDevice)
            : base(graphicsDevice, "Perlin2D") {
        }
    }
}