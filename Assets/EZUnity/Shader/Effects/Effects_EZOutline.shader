// Author:			ezhex1991@outlook.com
// CreateTime:		2018-08-31 16:41:15
// Organization:	#ORGANIZATION#
// Description:		

Shader "EZUnity/Effects/EZOutline" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}

		_DepthSensitivity ("Depth Sensitivity", Float) = 10
		_NormalSensitivity ("Normal Sensitivity", Float) = 5

		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_OutlineThickness ("Outline Thickness", Float) = 1
	}
	SubShader {
		Tags { "RenderType" = "Opaque" }
		Cull Off
		ZWrite Off
		ZTest Always

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv[5] : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _CameraDepthNormalsTexture;

			fixed _DepthSensitivity;
			fixed _NormalSensitivity;

			fixed4 _OutlineColor;
			fixed _OutlineThickness;

			int edgeCheck (float4 sample1, float4 sample2) {
				fixed2 normal1 = sample1.xy;
				fixed depth1 = DecodeFloatRG(sample1.zw);
				fixed2 normal2 = sample2.xy;
				fixed depth2 = DecodeFloatRG(sample2.zw);

				fixed2 normalDiff = abs(normal1 - normal2);
				int normalCheck = (normalDiff.x + normalDiff.y) * _NormalSensitivity < 1.0;
				int depthCheck = abs(depth1 - depth2) * _DepthSensitivity < 1.0;
				return normalCheck * depthCheck ? 0 : 1;
			}
			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv[0] = v.uv;
				float2 uv = v.uv;
				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						uv.xy = 1 - uv.xy;
				#endif
				o.uv[1] = uv + _MainTex_TexelSize.xy * float2(1, 1) * _OutlineThickness;
				o.uv[2] = uv + _MainTex_TexelSize.xy * float2(-1, 1) * _OutlineThickness;
				o.uv[3] = uv + _MainTex_TexelSize.xy * float2(-1, -1) * _OutlineThickness;
				o.uv[4] = uv + _MainTex_TexelSize.xy * float2(1, -1) * _OutlineThickness;
				return o;
			}
			fixed4 frag (v2f i) : SV_Target {
				fixed4 color = tex2D(_MainTex, i.uv[0]);
				float4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
				float4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
				float4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
				float4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);
				int edge = 0;
				edge += edgeCheck(sample1, sample3);
				edge += edgeCheck(sample2, sample4);
				return lerp(color, _OutlineColor, edge * _OutlineColor.a);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
