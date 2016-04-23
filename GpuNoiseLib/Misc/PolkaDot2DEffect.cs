using Microsoft.Xna.Framework.Graphics;

namespace GpuNoiseLib.Misc {
    public class PolkaDot2DEffect : GnlEffect {

        private readonly EffectParameter _radiusLowParam;
        private readonly EffectParameter _radiusHighParam;

        public float RadiusLow { get; set; } = 0.15f;
        public float RadiusHigh { get; set; } = 0.4f;

        public PolkaDot2DEffect(GraphicsDevice graphicsDevice)
            : base(graphicsDevice, "Polka2D") {
            _radiusLowParam = Parameters["RadiusLow"];
            _radiusHighParam = Parameters["RadiusHigh"];

            CurrentTechnique = Techniques["PolkaDot2D"];
        }

        protected override bool OnApply() {
            _radiusLowParam.SetValue(RadiusLow);
            _radiusHighParam.SetValue(RadiusHigh);
            return base.OnApply();
        }
    }
}