using Microsoft.Xna.Framework.Graphics;

namespace GpuNoiseLib.Misc {
    public class Stars2DEffect : GnlEffect {

        private readonly EffectParameter _probabilityThreshParam;
        private readonly EffectParameter _maxDimnessParam;
        private readonly EffectParameter _twoOverRadiusParam;

        public float ProbabilityThresh { get; set; } = 0.1f; // ( 0.0->1.0 )
        public float MaxDimness { get; set; } = 0.4f; // ( 0.0->1.0 )
        public float Radius { get; set; } = 0.5f; // ( 0.0->1.0 )

        public Stars2DEffect(GraphicsDevice graphicsDevice)
            : base(graphicsDevice, "Stars2D") {
            _probabilityThreshParam = Parameters["ProbabilityThresh"];
            _maxDimnessParam = Parameters["MaxDimness"];
            _twoOverRadiusParam = Parameters["TwoOverRadius"];

            CurrentTechnique = Techniques["Stars2D"];
        }

        protected override bool OnApply() {
            _probabilityThreshParam.SetValue(ProbabilityThresh);
            _maxDimnessParam.SetValue(MaxDimness);
            _twoOverRadiusParam.SetValue(2f / Radius);
            return base.OnApply();
        }
    }
}