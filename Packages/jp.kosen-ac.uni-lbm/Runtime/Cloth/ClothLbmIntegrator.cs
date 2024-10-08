﻿using System.Diagnostics.CodeAnalysis;
using UniLbm.Common;
using UniLbm.Lbm;
using Unity.Mathematics;
using UnityEngine;

namespace UniLbm.Cloth
{
    /// <summary>
    ///     布をLBM上の境界としてボクセル化する
    /// </summary>
    public class ClothLbmIntegrator
    {
        private readonly ClothSolver _clothSolver;
        private readonly LbmParticle _lbmParticle;
        private readonly ILbmSolver _lbmSolver;
        private readonly ComputeShaderWrapper<Kernels, Uniforms> _shader;

        public ClothLbmIntegrator(ComputeShader shader, ClothSolver clothSolver, ILbmSolver lbmSolver,
            LbmParticle lbmParticle, in Data data)
        {
            _shader = new ComputeShaderWrapper<Kernels, Uniforms>(shader);
            _clothSolver = clothSolver;
            _lbmSolver = lbmSolver;
            _lbmParticle = lbmParticle;

            SetBuffers();
            SetData(in data, true);
        }

        public void Update()
        {
            var clothRes = _clothSolver.ClothResolution;
            _shader.Dispatch(Kernels.main, new uint3(new uint2(clothRes), 1));
        }

        public void Reset()
        {
            var clothRes = _clothSolver.ClothResolution;
            _shader.Dispatch(Kernels.reset, new uint3(new uint2(clothRes), 1));
        }

        #region ComputeShader

        private void SetBuffers()
        {
            _shader.SetTexture(Kernels.main, Uniforms.pos_buffer, _clothSolver.PositionBuffer);
            _shader.SetBuffer(Kernels.main, Uniforms.field_buffer, _lbmSolver.FieldBuffer);
            _shader.SetTexture(Kernels.reset, Uniforms.external_force_buffer, _clothSolver.ExternalForceBuffer);
        }

        public void SetData(in Data data, bool isInit = false)
        {
            if (isInit)
            {
                var clothRes = _clothSolver.ClothResolution;
                _shader.SetInts(Uniforms.cloth_res, clothRes.x, clothRes.y);
                _shader.SetInt(Uniforms.lbm_res, _lbmSolver.CellRes);
                _shader.SetInt(Uniforms.lbm_boundary_size, _lbmParticle.Bounds);
            }
            
            _shader.SetFloat(Uniforms.lbm_cell_size, data.LbmCellSize);
            _shader.SetMatrix(Uniforms.transform, data.Transform);
        }

        [SuppressMessage("ReSharper", "InconsistentNaming")]
        private enum Kernels
        {
            main,
            reset
        }

        [SuppressMessage("ReSharper", "InconsistentNaming")]
        private enum Uniforms
        {
            pos_buffer,
            field_buffer,
            external_force_buffer,
            cloth_res,
            lbm_res,
            lbm_boundary_size,
            lbm_cell_size,
            transform
        }

        public readonly struct Data
        {
            public float LbmCellSize { get; init; }
            public float4x4 Transform { get; init; }
        }

        #endregion
    }
}