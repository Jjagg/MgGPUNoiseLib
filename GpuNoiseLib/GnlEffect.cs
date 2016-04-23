using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Policy;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GpuNoiseLib {
    public class GnlEffect : Effect {

        private readonly EffectParameter _matrixParam;
        private readonly EffectParameter _offsetParam;
        private readonly EffectParameter _scaleParam;
        private readonly EffectParameter _postOffsetParam;
        private readonly EffectParameter _postScaleParam;

        public Vector2 Offset { get; set; } = Vector2.Zero;
        public Vector2 Scale { get; set; } = Vector2.One;
        public float PostOffset { get; set; } = 0f;
        public float PostScale { get; set; } = 1f;

        private static bool IsUsingDX() {
            // use reflection to figure out if Shader.Profile is OpenGL (0) or DirectX (1)
            return true;
            var mgAssembly = Assembly.GetAssembly(typeof (Game));
            var shaderType = mgAssembly.GetType("Microsoft.Xna.Framework.Graphics.Shader");
            var profileProperty = shaderType.GetProperty("Profile");
            var value = (int) profileProperty.GetValue(null);
            return value == 1;
        }

        public const string ShaderPrefix = "GpuNoiseLib.Shaders.Compiled.";
        public static readonly string ShaderExtension = IsUsingDX() ? ".dx11.mgfxo" : ".ogl.mgfxo";

        public GnlEffect(GraphicsDevice graphicsDevice, string shaderName)
            : base(graphicsDevice, LoadShaderBytes(ShaderPrefix + shaderName + ShaderExtension)) {
            _matrixParam = Parameters["Transform"];
            _offsetParam = Parameters["PreOffset"];
            _scaleParam = Parameters["PreScale"];
            _postOffsetParam = Parameters["PostOffset"];
            _postScaleParam = Parameters["PostScale"];
        }

        private static byte[] LoadShaderBytes(string name) {
            var stream = typeof (GnlEffect).Assembly.GetManifestResourceStream(name);
            using (var ms = new MemoryStream()) {
                stream.CopyTo(ms);
                return ms.ToArray();
            }
        }

        public Texture2D Render(Point size) {
            return Render(new Rectangle(Point.Zero, size));
        }

        public Texture2D Render(Rectangle rect) {
            var size = rect.Size;
            var target = new RenderTarget2D(GraphicsDevice, size.X, size.Y);
            var prevTargets = GraphicsDevice.GetRenderTargets();

            var verts = new[] {
                new VertexPosition(new Vector3(rect.Left, rect.Top, 0)),
                new VertexPosition(new Vector3(rect.Right, rect.Top, 0)),
                new VertexPosition(new Vector3(rect.Left, rect.Bottom, 0)),
                new VertexPosition(new Vector3(rect.Right, rect.Bottom, 0)),
            };
            var buffer = new VertexBuffer(GraphicsDevice, typeof (VertexPosition), 6, BufferUsage.WriteOnly);
            buffer.SetData(verts);

            GraphicsDevice.SetVertexBuffer(buffer);

            GraphicsDevice.SetRenderTarget(target);
            GraphicsDevice.Clear(Color.CornflowerBlue);

            foreach (var pass in CurrentTechnique.Passes) {
                pass.Apply();
                GraphicsDevice.DrawPrimitives(PrimitiveType.TriangleStrip, 0, 2);
            }


            GraphicsDevice.SetRenderTargets(prevTargets);
            return target;
        }

        protected override bool OnApply() {
            var vp = GraphicsDevice.Viewport;
            var matrix = Matrix.CreateOrthographicOffCenter(0, vp.Width, vp.Height, 0, 0, 1);
            _matrixParam.SetValue(matrix);
            _offsetParam.SetValue(Offset);
            _scaleParam.SetValue(Scale * 0.05f);
            _postOffsetParam.SetValue(PostOffset);
            _postScaleParam.SetValue(PostScale);
            return false;
        }

    }
}