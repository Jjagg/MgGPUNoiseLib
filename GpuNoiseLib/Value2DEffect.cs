using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GpuNoiseLib {
    public class Value2DEffect : FbmEffect {
        public Value2DEffect(GraphicsDevice graphicsDevice)
            : base(graphicsDevice, "Value2D") {
        }
    }
}