﻿using System;
using Effector.Impl;
using Solver.Impls;
using Unity.Mathematics;
using UnityEngine;

namespace Solver
{
    public class LbmSolverBehaviour : MonoBehaviour
    {
        [SerializeField] private ComputeShader lbmShader, effectorShader;
        [SerializeField] private Material effectorMaterial;
        [SerializeField] private uint width = 50;
        [SerializeField] private uint height = 50;
        [SerializeField] private uint depth = 50;
        [SerializeField] private float tau = 0.91f;
        [SerializeField] private Vector3 force = new(0.0002f, 0, 0);
        [SerializeField] private Solvers solverType;
        [SerializeField] private uint maxPoints = 100000;
        private PointEffector _effector;

        private UniLbmSolverBase _solver;

        private void Start()
        {
            _solver = solverType switch
            {
                Solvers.D3Q15 => new ComputeD3Q15Solver(lbmShader, new uint3(width, height, depth), tau, force),
                Solvers.D3Q19 => new ComputeD3Q19Solver(lbmShader, tau, new uint3(width, height, depth)),
                _ => throw new NotImplementedException()
            };
            _effector = new PointEffector(new uint3(width, height, depth), maxPoints, effectorShader,
                effectorMaterial,
                _solver.GetFieldBuffer(), _solver.GetVelocityBuffer());
        }

        private void Update()
        {
            _solver.Step();
            _effector.Update();
        }

        private void OnDestroy()
        {
            _solver?.Dispose();
            _effector?.Dispose();

            _solver = null;
            _effector = null;
        }

        private enum Solvers
        {
            D3Q15,
            D3Q19
        }
    }
}