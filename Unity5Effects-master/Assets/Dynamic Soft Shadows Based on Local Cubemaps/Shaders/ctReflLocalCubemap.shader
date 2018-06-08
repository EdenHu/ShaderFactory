// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"Custom/ctReflLocalCubemap"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" { }
        _Cube("Reflection Map", Cube) = "" {}
        _AmbientColor("Ambient Color", Color) = (1, 1, 1, 1)
        _ReflAmount("Reflection Amount", Float) = 0.5
    }

    SubShader
    {
        Pass
        {  
            CGPROGRAM
            #pragma glsl
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
           // User-specified uniforms
            uniform sampler2D _MainTex;
            uniform samplerCUBE _Cube;
            uniform float4 _AmbientColor;
            uniform float _ReflAmount;
            uniform float _ToggleLocalCorrection;
           // ----Passed from script InfoRoReflmaterial.cs --------
            uniform float3 _BBoxMin;
            uniform float3 _BBoxMax;
            uniform float3 _EnviCubeMapPos;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float4 tex : TEXCOORD0;
                float3 vertexInWorld : TEXCOORD1;
                float3 viewDirInWorld : TEXCOORD2;
                float3 normalInWorld : TEXCOORD3;
            };


			vertexOutput vert(vertexInput input)

{

    vertexOutput output;

    output.tex = input.texcoord;

    // Transform vertex coordinates from local to world.

    float4 vertexWorld = mul(unity_ObjectToWorld, input.vertex);

    // Transform normal to world coordinates.

    float4 normalWorld = mul(float4(input.normal, 0.0), unity_WorldToObject);

    // Final vertex output position.   

    output.pos = UnityObjectToClipPos(input.vertex);

    // ----------- Local correction ------------

    output.vertexInWorld = vertexWorld.xyz;

    output.viewDirInWorld = vertexWorld.xyz - _WorldSpaceCameraPos;

    output.normalInWorld = normalWorld.xyz;

    return output;

}

float3 LocalCorrect(float3 origVec, float3 bboxMin, float3 bboxMax, float3 vertexPos, float3 cubemapPos)

{

    // Find the ray intersection with box plane

    float3 invOrigVec = float3(1.0,1.0,1.0)/origVec;

    float3 intersecAtMaxPlane = (bboxMax - vertexPos) * invOrigVec;

    float3 intersecAtMinPlane = (bboxMin - vertexPos) * invOrigVec;

    // Get the largest intersection values (we are not intersted in negative values)

    float3 largestIntersec = max(intersecAtMaxPlane, intersecAtMinPlane);

    // Get the closest of all solutions

   float Distance = min(min(largestIntersec.x, largestIntersec.y), largestIntersec.z);

    // Get the intersection position

    float3 IntersectPositionWS = vertexPos + origVec * Distance;

    // Get corrected vector

    float3 localCorrectedVec = IntersectPositionWS - cubemapPos;

    return localCorrectedVec;

}

float4 frag(vertexOutput input) : COLOR

{

     float4 reflColor = float4(1, 1, 0, 0);

     // Find reflected vector in WS.

    float3 viewDirWS = normalize(input.viewDirInWorld);

     float3 normalWS = normalize(input.normalInWorld);

     float3 reflDirWS = reflect(viewDirWS, normalWS);

     // Get local corrected reflection vector.

      float3 localCorrReflDirWS = LocalCorrect(reflDirWS, _BBoxMin, _BBoxMax,

                                                      input.vertexInWorld, _EnviCubeMapPos);

     // Lookup the environment reflection texture with the right vector.

    reflColor = texCUBE(_Cube, localCorrReflDirWS);

     // Lookup the texture color.

     float4 texColor = tex2D(_MainTex, input.tex.xy);

     return _AmbientColor + texColor * _ReflAmount * reflColor;

}
           
            ENDCG
          }
      }
}