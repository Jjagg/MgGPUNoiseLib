using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GpuNoiseLib {
    public abstract class FbmEffect : GnlEffect {
        #region Params

        private readonly EffectParameter _octavesParam;
        private readonly EffectParameter _frequencyParam;
        private readonly EffectParameter _amplitudeParam;
        private readonly EffectParameter _lacunarityParam;
        private readonly EffectParameter _persistenceParam;

        private readonly EffectParameter _ridgePower;

        private readonly EffectParameter _warpParam;

        private readonly EffectParameter _jordanInitGainParam;
        private readonly EffectParameter _jordanInitWarpParam;
        private readonly EffectParameter _jordanInitDampParam;
        private readonly EffectParameter _jordanDampParam;
        private readonly EffectParameter _jordanDampScaleParam;

        #endregion

        #region Properties

        public int Octaves { get; set; } = 5;
        public Vector2 Frequency { get; set; } = Vector2.One;
        public float Amplitude { get; set; } = 1f;
        public Vector2 Lacunarity { get; set; } = new Vector2(2f);
        public float Persistence { get; set; } = 0.7f;

        public float RidgePower { get; set; } = 3f;

        public float Warp { get; set; } = 0.50f;

        public float JordanInitGain { get; set; } = 0.8f;
        public float JordanInitWarp { get; set; } = 0.4f;
        public float JordanInitDamp { get; set; } = 1.0f;
        public float JordanDamp { get; set; } = 0.8f;
        public float JordanDampScale { get; set; } = 1.0f;

        #endregion

        public FbmEffect(GraphicsDevice graphicsDevice, string shaderName) : base(graphicsDevice, shaderName) {
            _octavesParam = Parameters["Octaves"];
            _frequencyParam = Parameters["Frequency"];
            _amplitudeParam = Parameters["Amplitude"];
            _lacunarityParam = Parameters["Lacunarity"];
            _persistenceParam = Parameters["Persistence"];

            _ridgePower = Parameters["RidgePower"];

            _warpParam = Parameters["Warp"];

            _jordanInitGainParam = Parameters["JordanInitGain"];
            _jordanInitWarpParam = Parameters["JordanInitWarp"];
            _jordanInitDampParam = Parameters["JordanInitDamp"];
            _jordanDampParam = Parameters["JordanDamp"];
            _jordanDampScaleParam = Parameters["JordanDampScale"];

            SetType(FbmType.None);
        }

        public void SetType(FbmType type) {
            switch (type) {
            case FbmType.None:
                CurrentTechnique = Techniques["Single"];
                break;
            case FbmType.Normal:
                CurrentTechnique = Techniques["Fbm"];
                break;
            case FbmType.Billowed:
                CurrentTechnique = Techniques["FbmBillow"];
                break;
            case FbmType.Ridged:
                CurrentTechnique = Techniques["FbmRidged"];
                break;
            case FbmType.IQ:
                CurrentTechnique = Techniques["FbmIQ"];
                break;
            case FbmType.Swiss:
                CurrentTechnique = Techniques["FbmSwiss"];
                break;
            case FbmType.Jordan:
                CurrentTechnique = Techniques["FbmJordan"];
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(type), type, null);
            }
        }

        protected override bool OnApply() {
            _octavesParam.SetValue(Octaves);
            _frequencyParam.SetValue(Frequency);
            _amplitudeParam.SetValue(Amplitude);
            _lacunarityParam.SetValue(Lacunarity);
            _persistenceParam.SetValue(Persistence);

            _ridgePower.SetValue(RidgePower);

            _warpParam.SetValue(Warp);

            _jordanInitGainParam.SetValue(JordanInitGain);
            _jordanInitWarpParam.SetValue(JordanInitWarp);
            _jordanInitDampParam.SetValue(JordanInitDamp);
            _jordanDampParam.SetValue(JordanDamp);
            _jordanDampScaleParam.SetValue(JordanDampScale);

            return base.OnApply();
        }

    }
}