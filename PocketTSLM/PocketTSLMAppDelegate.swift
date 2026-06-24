//
// This source file is part of the PocketTSLM project
//
// SPDX-FileCopyrightText: 2026 The Authors
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziLLM
import SpeziLLMLocal
import SwiftUI


class PocketTSLMAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: HealthyStandard()) {
            LLMRunner {
                LLMLocalPlatform()
            }
            HealthDataInterpreter()
            OpenTSLMInferenceService()
        }
    }
}

actor HealthyStandard: Standard {}
