<!--

This source file is part of the PocketTSLM project

SPDX-FileCopyrightText: 2023 The Authors

SPDX-License-Identifier: MIT

-->

# PocketTSLM

**PocketTSLM** ports a soft-prompt time-series language model (OpenTSLM-SP) to run fully on-device with MLX-Swift: the encoder, projector, and LLM all execute on an iPhone, so physiological time series (ECG, EEG) can be interpreted in natural language without sending health data off the device. This repository holds the iOS app, the Python↔Swift numerical-parity tests, and the on-device context-economics benchmark reported in the paper.

## Repository layout

- `PocketTSLM/` — the iOS app and the on-device inference + benchmark code.
- `src-swift/` — the `OpenTSLMKit` Swift package (encoder, projector, interleaver, serializer) and its parity tests.
- `PocketTSLM/Supporting Files/OpenTSLM/` — bundled evaluation samples and converted MLX checkpoints.
- `benchmark-results/` — reference benchmark outputs from our run.
- `scripts/` — checkpoint conversion and dataset export helpers.

## Reproducing the paper

Requires macOS + Xcode, an Apple-silicon iPhone (for the latency/memory numbers), and a Hugging Face token: `meta-llama/Llama-3.2-1B` is gated, so accept its license and set `HF_TOKEN` in your (unshared) Xcode Run scheme.

**Parity tests (§3).** Component-level Python↔Swift parity (encoder, projector, fused pipeline, soft-prompt interleaver, RoPE, tokenizer, text serializer) against committed fixtures — no Python needed:

```bash
cd src-swift && swift test          # CI runs: fastlane test
```

Tolerances are max 1e-4 / mean 1e-5 (1e-3 for RoPE). The greedy decode itself runs in the app (`OpenTSLMLLM`); the tests cover the pipeline that feeds it.

**Benchmark (§4).** Run the app on an iPhone and tap **EEG bench** / **ECG bench**: each sweeps time-series tokens, time-to-first-token, and peak memory, and writes `opentslm_context_economics[_ecg].json` to the app's Documents directory. Our reference outputs (iPhone Air, iOS 26.4.1, MLX-Swift 0.30.6) are in `benchmark-results/`.

**Data & checkpoints.** Under `PocketTSLM/Supporting Files/OpenTSLM/`: `sleep_cot.csv` (EEG) and `ecg_qa_cot_test_0.json` (ECG) samples, plus `mlx-checkpoint.*.safetensors` weights (converted via `scripts/convert_opentslm_checkpoint.py`).

## License

MIT — see `LICENSE.md`.
