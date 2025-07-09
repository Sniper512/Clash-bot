// AI Attack Analyzer - Genkit-powered functions for Clash of Clans bot
import {
	gemini15Flash,
	gemini15Pro,
	gemini20Flash,
	googleAI,
} from "@genkit-ai/googleai";
import { genkit } from "genkit";
import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";

// Get current directory for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config({ path: ".env.local" });

// Check if API key is loaded
const apiKey = process.env.GOOGLE_API_KEY;
if (!apiKey) {
	console.error("❌ GOOGLE_API_KEY not found in environment variables");
	process.exit(1);
} else {
	console.log("✅ Google API key loaded successfully");
}

// Initialize Genkit with multiple models
const ai = genkit({
	plugins: [googleAI()],
	model: gemini20Flash, // Updated to use Gemini 2.0 Flash for text-only analysis
});

// Initialize vision models for fallback support
const visionModels = [
	{
		name: "Gemini 1.5 Pro",
		model: gemini15Pro,
		ai: genkit({ plugins: [googleAI()], model: gemini15Pro }),
	},
	{
		name: "Gemini 2.0 Flash",
		model: gemini20Flash,
		ai: genkit({ plugins: [googleAI()], model: gemini20Flash }),
	},
];

// Initialize primary vision AI (we'll use fallback logic in the function)
const visionAI = visionModels[0].ai;

// Initialize Express app
const app = express();
app.use(cors());
app.use(express.json({ limit: "50mb" }));

// Serve static files (for the web interface)
app.use(express.static("Server"));

const PORT = process.env.PORT || 3000;

// Health check endpoint
app.get("/health", async (req, res) => {
	try {
		// Test basic server health
		const serverHealth = {
			status: "ok",
			message: "AI Attack Analyzer is running",
		};

		// Optional: Test AI connectivity (only if query parameter is provided)
		if (req.query.testAI === "true") {
			try {
				console.log("🧪 Testing AI connectivity...");
				const testResult = await ai.generate({
					prompt: "Test connection. Please respond with 'OK'.",
				});
				serverHealth.aiConnection = "ok";
				serverHealth.aiResponse = testResult.text;
			} catch (aiError) {
				console.error("AI connectivity test failed:", aiError);
				serverHealth.aiConnection = "failed";
				serverHealth.aiError = aiError.message;
			}
		}

		res.json(serverHealth);
	} catch (error) {
		res.status(500).json({
			status: "error",
			message: "Health check failed",
			error: error.message,
		});
	}
});

// Serve the web interface
app.get("/", (req, res) => {
	res.sendFile(path.join(__dirname, "web-interface.html"));
});

// Serve the bot test interface
app.get("/bot-test", (req, res) => {
	res.sendFile(path.join(__dirname, "bot-test.html"));
});

// Helper function to analyze base image with vision model and fallback support
async function analyzeBaseImage(imageData, customPrompt) {
	const visionPrompt =
		customPrompt ||
		`
	You are an expert Clash of Clans base analyzer for BOT AUTOMATION. Analyze this base image and provide a comprehensive analysis that can be used by an automated bot.

	**IMPORTANT FOR BOT INTEGRATION:**
	- Use clear directional references that can be converted to coordinates
	- Provide specific, actionable commands that a bot can execute
	- Use consistent terminology that matches bot functions
	- Give precise deployment zones and target locations

	**DETAILED BASE ANALYSIS:**

	1. **Town Hall Level:** [Identify exact TH level: 1-16]

	2. **Base Type:** [War Base, Farming Base, Trophy Base, or Hybrid Base]

	3. **Base Layout:** [Centralized, Spread Out, Ring Base, Anti-3 Star, etc.]

	4. **Defense Locations (Bot-Readable):**
	   - **Eagle Artillery:** [Position: Center/North/South/East/West + distance from center]
	   - **Inferno Towers:** [List each position with cardinal direction + approximate distance]
	   - **X-Bows:** [Position and target setting if visible]
	   - **Air Defenses:** [All 4 positions with cardinal directions]
	   - **Wizard Towers:** [Each position relative to center or walls]
	   - **Mortars:** [Position for each mortar]
	   - **Archer Towers:** [List key positions]
	   - **Cannons:** [Main positions]

	5. **Resource Targets (Priority Order):**
	   - **Town Hall:** [Exact position: Center-North, Center-South, etc.]
	   - **Dark Elixir Storage:** [Position relative to TH]
	   - **Gold Storages:** [List positions in priority order]
	   - **Elixir Storages:** [List positions in priority order]

	6. **Wall Analysis for Bot:**
	   - **Outer Wall Weak Points:** [List 3-5 best wall breaking locations with directions]
	   - **Compartment Entry Points:** [Specific wall sections to target]
	   - **Path to Core:** [Describe route from outer wall to TH/center]

	7. **Bot Attack Zones:**
	   - **Primary Deploy Zone:** [Cardinal direction + specific location (e.g., "South side, 30% from Southwest corner")]
	   - **Secondary Deploy Zone:** [Alternative approach]
	   - **Avoid Zones:** [Areas with heavy defense concentration]

	8. **Bot-Executable Targets:**
	   - **First Wall Target:** [Specific wall section with direction]
	   - **Tank Deployment:** [Where to place Giants/Golems with cardinal direction]
	   - **DPS Deployment:** [Where to place Wizards/Archers behind tanks]
	   - **Hero Entry Point:** [When and where to deploy heroes]
	   - **Spell Drop Zones:** [Specific areas for Heal/Rage spells]

	**OUTPUT FORMAT FOR BOT:**
	Format all positions as: [Direction][Distance] (e.g., "North-Center", "Southwest-Edge", "East-25%")
	`;

	// Try each vision model in order until one succeeds
	for (let i = 0; i < visionModels.length; i++) {
		const modelInfo = visionModels[i];

		try {
			console.log(
				`🔍 Attempting base image analysis with ${modelInfo.name}... (Attempt ${
					i + 1
				}/${visionModels.length})`
			);

			const visionResult = await modelInfo.ai.generate({
				prompt: visionPrompt,
				media: imageData,
			});

			console.log(`✅ Vision analysis successful with ${modelInfo.name}`);
			return {
				analysis: visionResult.text,
				modelUsed: modelInfo.name,
			};
		} catch (error) {
			console.error(`❌ ${modelInfo.name} failed:`, error.message);

			// Check if this is a quota/rate limit error
			const isQuotaError =
				error.message.includes("quota") ||
				error.message.includes("rate limit") ||
				error.message.includes("429") ||
				error.message.includes("Too Many Requests");

			const isAuthError =
				error.message.includes("API key") ||
				error.message.includes("unauthorized") ||
				error.message.includes("401") ||
				error.message.includes("403");

			// If it's an auth error, don't try other models
			if (isAuthError) {
				throw new Error(`API authentication failed: ${error.message}`);
			}

			// If it's not a quota error and not the last model, don't continue fallback
			if (!isQuotaError && i < visionModels.length - 1) {
				console.log(`🔄 Non-quota error encountered, trying next model...`);
			}

			// If this is the last model, throw the error
			if (i === visionModels.length - 1) {
				throw new Error(
					`All vision models failed. Last error from ${modelInfo.name}: ${error.message}`
				);
			}

			// Log that we're falling back to the next model
			if (isQuotaError) {
				console.log(
					`⚠️ ${modelInfo.name} hit quota limit, trying fallback model...`
				);
			}
		}
	}
}

// Helper function to create attack strategy based on base analysis
async function createAttackStrategy(
	baseAnalysis,
	troopComposition,
	targetResources
) {
	const strategyPrompt = `
	You are an expert Clash of Clans attack strategist creating a BOT-EXECUTABLE attack plan. Based on the detailed base analysis provided below, create an optimal attack strategy that a bot can follow step-by-step.

	**BASE ANALYSIS:**
	${baseAnalysis}

	**AVAILABLE TROOPS:**
	${troopComposition || "Standard army composition"}

	**TARGET OBJECTIVES:**
	${targetResources || "Gold, Elixir, Dark Elixir"}

	**CREATE BOT-EXECUTABLE ATTACK STRATEGY:**

	1. **Attack Type:** [GoWiPe, LavaLoon, Hog Rider, Barch, Mass Dragons, etc.]

	2. **BOT EXECUTION SEQUENCE (Step-by-Step):**
	   - **STEP 1:** DEPLOY [troop type] AT [specific location with direction] 
	   - **STEP 2:** WAIT [seconds] THEN DEPLOY [wall breakers] AT [wall section with direction]
	   - **STEP 3:** DEPLOY [main force] AT [specific zone] BEHIND [tank troops]
	   - **STEP 4:** WAIT [seconds] FOR [condition] THEN DEPLOY [support troops]
	   - **STEP 5:** DEPLOY [heroes] AT [location] WHEN [tank troops reach X]
	   - **STEP 6:** DROP [spell] AT [location] WHEN [condition met]
	   - **STEP 7:** DEPLOY [cleanup troops] AT [remaining targets]

	3. **BOT DEPLOYMENT COORDINATES:**
	   - **Primary Deploy Zone:** [Direction + % from edge] (e.g., "South-30%" means 30% from south edge)
	   - **Wall Break Target:** [Direction + specific wall section] (e.g., "West-outer-wall-near-cannon")
	   - **Spell Drop Locations:** [Exact positions for each spell]
	   - **Hero Entry Point:** [Direction + timing condition]

	4. **BOT TARGET PRIORITY:**
	   - **Primary:** [Most important building with location]
	   - **Secondary:** [Next targets in order]
	   - **Cleanup:** [Low priority targets]

	5. **BOT TIMING CONDITIONS:**
	   - **Wait Conditions:** [When to proceed to next step]
	   - **Health Triggers:** [When to drop healing spells]
	   - **Rage Triggers:** [When to drop rage spells]
	   - **Hero Ability Timing:** [When to activate abilities]

	6. **BOT DECISION POINTS:**
	   - **IF [condition] THEN [action]**
	   - **IF tanks destroyed BEFORE reaching center, THEN [backup plan]**
	   - **IF defenses focus on one side, THEN [redirect strategy]**

	**IMPORTANT FOR BOT:** Use EXACT directional references (North, South, East, West, Northeast, etc.) and specific timing (wait 3 seconds, wait for 50% damage, etc.)
	   - Backup plans if initial strategy fails

	8. **Resource Gain Estimation:**
	   - Expected resource gain
	   - Most profitable targets to focus on

	**IMPORTANT:** Provide specific, actionable instructions based on the base analysis. Use the exact positional references from the base analysis (e.g., "Deploy Giants at the North side where the Archer Tower is positioned").
	`;

	try {
		console.log("🧠 Creating attack strategy with strategy model...");
		const strategyResult = await ai.generate({
			prompt: strategyPrompt,
		});

		return strategyResult.text;
	} catch (error) {
		console.error("Strategy creation error:", error);
		throw new Error(`Strategy creation failed: ${error.message}`);
	}
}

// 1. Base Analysis - Analyze enemy base layout and suggest optimal attack strategy
app.post("/api/analyze-base", async (req, res) => {
	try {
		const {
			baseImage,
			troopComposition,
			targetResources,
			baseLayout,
			defensePositions,
			wallConfiguration,
		} = req.body;

		// If no image provided, use text-based analysis
		if (!baseImage && !baseLayout) {
			return res.status(400).json({
				success: false,
				error: "Base image or base layout description is required for analysis",
			});
		}

		let baseAnalysis;
		let attackStrategy;

		if (baseImage) {
			// Image-based analysis using two-step process
			console.log("🖼️ Processing image-based base analysis...");
			console.log("📊 Image data length:", baseImage.length);
			console.log("📊 Image starts with:", baseImage.substring(0, 50));

			// Validate that we actually have image data
			if (baseImage.length < 100) {
				throw new Error(
					"Invalid or empty image data provided. Please upload a valid base image."
				);
			}

			// Prepare the image data for Gemini Vision
			let imageData = null;
			if (baseImage.startsWith("data:image/")) {
				// Handle base64 encoded images
				const base64Data = baseImage.split(",")[1];
				if (!base64Data || base64Data.length < 50) {
					throw new Error(
						"Invalid base64 image data. Please upload a valid image file."
					);
				}
				imageData = {
					inlineData: {
						data: base64Data,
						mimeType: baseImage.split(";")[0].split(":")[1],
					},
				};
				console.log("📷 Prepared base64 image data for vision analysis");
			} else {
				// Handle image URLs or file paths
				imageData = {
					fileData: {
						fileUri: baseImage,
						mimeType: "image/png",
					},
				};
				console.log("📷 Prepared file URI image data for vision analysis");
			}

			try {
				// Step 1: Analyze the base image with vision model (with fallback support)
				console.log(
					"📸 Step 1: Analyzing base image with Gemini Vision (with fallback)..."
				);
				const visionResult = await analyzeBaseImage(imageData);
				baseAnalysis = visionResult.analysis;
				const modelUsed = visionResult.modelUsed;
				console.log(
					`✅ Vision analysis complete with ${modelUsed}, found base details`
				);

				// Step 2: Create attack strategy based on the analysis
				console.log(
					"🧠 Step 2: Creating attack strategy based on vision analysis..."
				);
				attackStrategy = await createAttackStrategy(
					baseAnalysis,
					troopComposition,
					targetResources
				);
				console.log("✅ Attack strategy created successfully");

				// Store model information for the response
				res.locals.visionModelUsed = modelUsed;
				res.locals.analysisType = "image-based";
			} catch (aiError) {
				console.error("AI Processing Error:", aiError);

				// Check if it's a network error
				if (
					aiError.message.includes("fetch failed") ||
					aiError.message.includes("network")
				) {
					throw new Error(
						"Network connectivity issue. Please check your internet connection and try again."
					);
				}

				// Check if it's an API key error
				if (
					aiError.message.includes("API key") ||
					aiError.message.includes("unauthorized")
				) {
					throw new Error(
						"API key issue. Please verify your Google API key is valid and has the correct permissions."
					);
				}

				// Check if all models failed
				if (aiError.message.includes("All vision models failed")) {
					throw new Error(
						`All available vision models have failed or hit quota limits. Please try again later. Details: ${aiError.message}`
					);
				}

				// Generic AI error
				throw new Error(`AI service error: ${aiError.message}`);
			}
		} else {
			// Text-based analysis (original approach)
			console.log("📝 Processing text-based base analysis...");

			const textPrompt = `
			You are an expert Clash of Clans attack strategist. Analyze this base layout description and provide strategic recommendations.
			
			Available troops: ${troopComposition || "Standard army composition"}
			Target resources: ${targetResources || "Gold, Elixir, Dark Elixir"}
			
			Base Layout Description:
			- Layout: ${baseLayout || "Unknown layout"}
			- Defense Positions: ${
				defensePositions
					? defensePositions.join(", ")
					: "Standard defense placement"
			}
			- Wall Configuration: ${wallConfiguration || "Standard wall setup"}
			
			Based on the base description provided, provide a detailed attack plan:
			
			1. **Base Analysis:**
			   - Base type classification (farming base, war base, trophy base)
			   - Town Hall level identification
			   - Defense placement analysis
			   - Resource storage locations
			
			2. **Vulnerability Assessment:**
			   - Weak points in the base design
			   - Gaps in wall coverage
			   - Poorly protected high-value targets
			   - Defense blind spots
			
			3. **Attack Strategy:**
			   - Recommended attack approach based on available troops
			   - Entry points for the attack
			   - Optimal troop deployment order
			   - Number of sides to attack from (1-4 sides)
			
			4. **Tactical Plan:**
			   - Where to deploy tanks (Giants, Golems) first
			   - Wall breaker placement for maximum effect
			   - Support troop positioning (Wizards, Archers)
			   - Hero deployment timing and location
			   - Spell usage recommendations and timing
			
			5. **Target Priority:**
			   - Primary targets (storages, town hall)
			   - Secondary targets (defenses to clear)
			   - Path planning for troops
			
			6. **Risk Assessment:**
			   - Success probability (low/medium/high)
			   - Potential troop losses
			   - Expected star count (1-3 stars)
			   - Resource gain potential
			
			Provide specific, actionable recommendations. Focus on creating a step-by-step attack plan that maximizes success with the given army composition.
			`;

			try {
				const textResult = await ai.generate({
					prompt: textPrompt,
				});

				baseAnalysis = "Text-based analysis - no image provided";
				attackStrategy = textResult.text;

				// Store analysis type for the response
				res.locals.visionModelUsed = "N/A (Text-based analysis)";
				res.locals.analysisType = "text-based";
			} catch (aiError) {
				console.error("AI Generation Error:", aiError);

				// Check if it's a network error
				if (
					aiError.message.includes("fetch failed") ||
					aiError.message.includes("network")
				) {
					throw new Error(
						"Network connectivity issue. Please check your internet connection and try again."
					);
				}

				// Check if it's an API key error
				if (
					aiError.message.includes("API key") ||
					aiError.message.includes("unauthorized")
				) {
					throw new Error(
						"API key issue. Please verify your Google API key is valid and has the correct permissions."
					);
				}

				// Generic AI error
				throw new Error(`AI service error: ${aiError.message}`);
			}
		}

		// Parse attack strategy and structure the response
		const analysis = {
			baseType: extractBaseType(attackStrategy),
			townHallLevel: extractTownHallLevel(baseAnalysis + " " + attackStrategy),
			weakPoints: extractWeakPoints(attackStrategy),
			recommendedStrategy: extractStrategy(attackStrategy),
			optimalSides: extractOptimalSides(attackStrategy),
			priorityTargets: extractPriorityTargets(attackStrategy),
			riskLevel: extractRiskLevel(attackStrategy),
			entryPoints: extractEntryPoints(attackStrategy),
			deploymentOrder: extractDeploymentOrder(attackStrategy),
			wallBreakerTargets: extractWallBreakerTargets(attackStrategy),
			heroDeployment: extractHeroDeployment(attackStrategy),
			spellTiming: extractSpellTiming(attackStrategy),
			pathPlanning: extractPathPlanning(attackStrategy),
			successProbability: extractSuccessProbability(attackStrategy),
			expectedStars: extractExpectedStars(attackStrategy),
			stepByStepPlan: extractStepByStepPlan(attackStrategy),
			baseAnalysis: baseImage ? baseAnalysis : "No image analysis performed",
			fullAnalysis: attackStrategy,
		};

		res.json({
			success: true,
			analysis: analysis,
			visionModelUsed: res.locals.visionModelUsed || "Unknown",
			analysisType: res.locals.analysisType || "unknown",
		});
	} catch (error) {
		console.error("Base analysis error:", error);
		res.status(500).json({
			success: false,
			error: "Failed to analyze base",
			details: error.message,
		});
	}
});

// 2. Troop Deployment Optimizer - Suggest optimal troop placement
app.post("/api/optimize-deployment", async (req, res) => {
	try {
		const { troopType, quantity, currentSituation, enemyDefenses } = req.body;

		const prompt = `
		As a Clash of Clans tactical expert, optimize the deployment of ${quantity} ${troopType} troops.
		
		Current battle situation: ${currentSituation}
		Enemy defenses status: ${enemyDefenses}
		
		Provide recommendations for:
		1. Optimal deployment coordinates (if specific areas are mentioned)
		2. Deployment timing (immediate, delayed, wave-based)
		3. Formation spread (concentrated, spread, targeted)
		4. Support troops needed
		5. Expected effectiveness (1-10 scale)
		
		Focus on maximizing damage while minimizing losses.
		`;

		const { text } = await ai.generate(prompt);

		const deployment = {
			timing: extractTiming(text),
			formation: extractFormation(text),
			supportTroops: extractSupportTroops(text),
			effectiveness: extractEffectiveness(text),
			recommendations: text,
		};

		res.json({
			success: true,
			deployment: deployment,
		});
	} catch (error) {
		console.error("Deployment optimization error:", error);
		res.status(500).json({
			success: false,
			error: "Failed to optimize deployment",
		});
	}
});

// 3. Real-time Battle Adaptation - Adapt strategy based on current battle state
app.post("/api/adapt-strategy", async (req, res) => {
	try {
		const { battleProgress, remainingTroops, enemyStatus, objectives } =
			req.body;

		const prompt = `
		Analyze this ongoing Clash of Clans battle and suggest tactical adaptations.
		
		Battle progress: ${battleProgress}%
		Remaining troops: ${remainingTroops}
		Enemy status: ${enemyStatus}
		Current objectives: ${objectives}
		
		Provide immediate tactical advice:
		1. Continue current strategy or pivot?
		2. Which troops to deploy next?
		3. Target priority adjustments
		4. Spell usage recommendations
		5. Hero ability timing
		6. Success probability assessment
		
		Give concise, actionable commands for immediate execution.
		`;

		const { text } = await ai.generate(prompt);

		const adaptation = {
			shouldPivot: extractPivotDecision(text),
			nextTroops: extractNextTroops(text),
			targetPriority: extractTargetPriority(text),
			spellRecommendations: extractSpellRecommendations(text),
			heroTiming: extractHeroTiming(text),
			successProbability: extractSuccessProbability(text),
			immediateActions: text,
		};

		res.json({
			success: true,
			adaptation: adaptation,
		});
	} catch (error) {
		console.error("Strategy adaptation error:", error);
		res.status(500).json({
			success: false,
			error: "Failed to adapt strategy",
		});
	}
});

// 4. Army Composition Optimizer - Suggest optimal army based on target base
app.post("/api/optimize-army", async (req, res) => {
	try {
		const { targetBaseType, availableTroops, attackGoal, townHallLevel } =
			req.body;

		const prompt = `
		Design an optimal army composition for Clash of Clans attack.
		
		Target base type: ${targetBaseType}
		Available troops: ${availableTroops}
		Attack goal: ${attackGoal}
		Town Hall level: ${townHallLevel}
		
		Recommend:
		1. Optimal troop composition with exact numbers
		2. Spell selection and quantities
		3. Hero selection priority
		4. Clan Castle troop request
		5. Attack strategy overview
		6. Expected star rating (1-3 stars)
		7. Resource gain potential
		
		Prioritize efficiency and success rate.
		`;

		const { text } = await ai.generate(prompt);

		const armyOptimization = {
			troopComposition: extractTroopComposition(text),
			spellSelection: extractSpellSelection(text),
			heroSelection: extractHeroSelection(text),
			clanCastleRequest: extractCCRequest(text),
			expectedStars: extractExpectedStars(text),
			resourceGain: extractResourceGain(text),
			fullRecommendation: text,
		};

		res.json({
			success: true,
			armyOptimization: armyOptimization,
		});
	} catch (error) {
		console.error("Army optimization error:", error);
		res.status(500).json({
			success: false,
			error: "Failed to optimize army",
		});
	}
});

// 5. Learning from Battle Results - Analyze battle outcome and improve future strategies
app.post("/api/learn-from-battle", async (req, res) => {
	try {
		const { battleResult, strategyUsed, troopsUsed, outcome, resources } =
			req.body;

		const prompt = `
		Analyze this Clash of Clans battle result and extract learning insights.
		
		Battle outcome: ${battleResult}
		Strategy used: ${strategyUsed}
		Troops deployed: ${troopsUsed}
		Result: ${outcome}
		Resources gained: ${resources}
		
		Provide analysis:
		1. What worked well?
		2. What could be improved?
		3. Strategy adjustments for similar bases
		4. Troop deployment lessons
		5. Timing optimization insights
		6. Overall performance score (1-10)
		7. Recommendations for future attacks
		
		Focus on actionable improvements.
		`;

		const { text } = await ai.generate(prompt);

		const learning = {
			successFactors: extractSuccessFactors(text),
			improvementAreas: extractImprovementAreas(text),
			strategyAdjustments: extractStrategyAdjustments(text),
			deploymentLessons: extractDeploymentLessons(text),
			performanceScore: extractPerformanceScore(text),
			futureRecommendations: extractFutureRecommendations(text),
			fullAnalysis: text,
		};

		res.json({
			success: true,
			learning: learning,
		});
	} catch (error) {
		console.error("Learning analysis error:", error);
		res.status(500).json({
			success: false,
			error: "Failed to analyze battle for learning",
		});
	}
});

// 6. Visual Attack Planner - Analyze base image and create detailed attack plan
app.post("/api/plan-attack-visual", async (req, res) => {
	try {
		const {
			baseImage,
			availableArmy,
			attackGoal = "resources",
			playerLevel = 11,
		} = req.body;

		if (!baseImage) {
			return res.status(400).json({
				success: false,
				error: "Base image is required for visual attack planning",
			});
		}

		const prompt = `
		As an expert Clash of Clans attack strategist, analyze this base image and create a comprehensive attack plan.
		
		**Available Army:** ${availableArmy || "Please specify army composition"}
		**Attack Goal:** ${attackGoal}
		**Player Level:** ${playerLevel}
		
		**VISUAL ANALYSIS REQUIRED:**
		Carefully examine the base image and provide:
		
		1. **Base Layout Recognition:**
		   - Identify all defensive buildings and their levels
		   - Locate resource storages (gold, elixir, dark elixir)
		   - Find the Town Hall and its protection level
		   - Map wall compartments and connections
		
		2. **Weakness Identification:**
		   - Spot gaps in wall coverage
		   - Identify poorly defended areas
		   - Find optimal entry points
		   - Locate isolated high-value targets
		
		3. **Attack Vector Analysis:**
		   - Best approach angles based on defense placement
		   - Safest deployment zones
		   - Path of least resistance to targets
		   - Potential funnel creation opportunities
		
		4. **Detailed Attack Plan:**
		   **Step 1:** Initial deployment (specify exact locations)
		   **Step 2:** Wall breaking strategy (target specific wall sections)
		   **Step 3:** Main force deployment (timing and positioning)
		   **Step 4:** Support deployment (cleanup and protection)
		   **Step 5:** Hero and spell usage (when and where)
		   **Step 6:** Adaptation points (what to do if plan goes wrong)
		
		5. **Success Metrics:**
		   - Expected star achievement (1-3 stars)
		   - Resource gain estimation
		   - Troop loss prediction
		   - Alternative plans if primary fails
		
		**IMPORTANT:** Base your recommendations ONLY on what you can see in the image. Provide specific locations using directional references (north, south, east, west, corners, center) that correspond to the actual base layout shown.
		
		Format as a clear, executable battle plan with specific coordinates and timing.
		`;

		// Prepare the image data for Gemini Vision
		let imageData = null;
		if (baseImage.startsWith("data:image/")) {
			const base64Data = baseImage.split(",")[1];
			imageData = {
				inlineData: {
					data: base64Data,
					mimeType: baseImage.split(";")[0].split(":")[1],
				},
			};
		} else {
			imageData = {
				fileData: {
					fileUri: baseImage,
					mimeType: "image/png",
				},
			};
		}

		// Generate visual attack plan
		const { text } = await ai.generate({
			prompt: prompt,
			media: imageData,
		});

		// Parse the detailed attack plan
		const attackPlan = {
			baseLayout: extractBaseLayout(text),
			weaknesses: extractWeaknesses(text),
			attackVectors: extractAttackVectors(text),
			detailedSteps: extractDetailedSteps(text),
			deploymentZones: extractDeploymentZones(text),
			wallTargets: extractWallTargets(text),
			heroStrategy: extractHeroStrategy(text),
			spellPlan: extractSpellPlan(text),
			successMetrics: extractSuccessMetrics(text),
			contingencyPlan: extractContingencyPlan(text),
			fullPlan: text,
		};

		res.json({
			success: true,
			attackPlan: attackPlan,
		});
	} catch (error) {
		console.error("Visual attack planning error:", error);
		res.status(500).json({
			success: false,
			error: "Failed to create visual attack plan",
			details: error.message,
		});
	}
});

// 7. Bot-Specific Attack Analysis - Returns structured data for bot automation
app.post("/api/bot-analyze", async (req, res) => {
	try {
		const { baseImage, troopComposition, targetResources } = req.body;

		if (!baseImage) {
			return res.status(400).json({
				success: false,
				error: "Base image is required for bot analysis",
			});
		}

		console.log("🤖 Processing bot-specific base analysis...");

		// Prepare the image data for Gemini Vision
		let imageData = null;
		if (baseImage.startsWith("data:image/")) {
			const base64Data = baseImage.split(",")[1];
			if (!base64Data || base64Data.length < 50) {
				throw new Error(
					"Invalid base64 image data. Please upload a valid image file."
				);
			}
			imageData = {
				inlineData: {
					data: base64Data,
					mimeType: baseImage.split(";")[0].split(":")[1],
				},
			};
		} else {
			imageData = {
				fileData: {
					fileUri: baseImage,
					mimeType: "image/png",
				},
			};
		}

		// Bot-specific vision analysis prompt
		const botVisionPrompt = `
		Analyze this Clash of Clans base image for PIXEL-BASED BOT AUTOMATION. The bot uses pixel coordinates for troop deployment along screen edges.

		**CRITICAL BOT REQUIREMENTS:**
		- Assume the game screen is 860x732 pixels (standard CoC resolution)
		- Provide pixel coordinates for deployment points along the screen edges
		- Map deployment zones to specific X,Y coordinates that DropTroop.au3 can use
		- Give precise pixel locations for targets and objectives
		- Coordinates should be relative to the game screen, not the base image

		**COORDINATE SYSTEM:**
		- Top edge: Y=40-80 (deployment zone)
		- Bottom edge: Y=650-690 (deployment zone)  
		- Left edge: X=40-80 (deployment zone)
		- Right edge: X=780-820 (deployment zone)
		- Center area: X=400-460, Y=350-380 (target area)

		**ANALYSIS FORMAT:**

		**TOWN_HALL_LEVEL:** [number 1-16]
		**BASE_TYPE:** [War/Farming/Trophy/Hybrid]
		**RECOMMENDED_STRATEGY:** [GoWiPe/LavaLoon/Barch/etc]

		**DEPLOYMENT_COORDINATES:** (Pixel coordinates for DropTroop.au3)
		PRIMARY_DEPLOY_X: [X coordinate 40-820]
		PRIMARY_DEPLOY_Y: [Y coordinate 40-690]
		SECONDARY_DEPLOY_X: [X coordinate 40-820] 
		SECONDARY_DEPLOY_Y: [Y coordinate 40-690]
		WALLBREAKER_X: [X coordinate for wall breaking]
		WALLBREAKER_Y: [Y coordinate for wall breaking]

		**TARGET_PIXEL_LOCATIONS:** (For targeting and spell placement)
		TOWN_HALL_X: [X coordinate 200-660]
		TOWN_HALL_Y: [Y coordinate 150-580]
		DARK_ELIXIR_X: [X coordinate]
		DARK_ELIXIR_Y: [Y coordinate]
		GOLD_STORAGE_1_X: [X coordinate]
		GOLD_STORAGE_1_Y: [Y coordinate]
		EAGLE_ARTILLERY_X: [X coordinate]
		EAGLE_ARTILLERY_Y: [Y coordinate]

		**EDGE_DEPLOYMENT_POINTS:** (Specific coordinates for different troop types)
		TANK_DEPLOY_X: [X coordinate on edge]
		TANK_DEPLOY_Y: [Y coordinate on edge]
		DPS_DEPLOY_X: [X coordinate behind tanks]
		DPS_DEPLOY_Y: [Y coordinate behind tanks]
		HERO_DEPLOY_X: [X coordinate for hero entry]
		HERO_DEPLOY_Y: [Y coordinate for hero entry]

		**SPELL_PIXEL_LOCATIONS:**
		HEAL_SPELL_X: [X coordinate for heal placement]
		HEAL_SPELL_Y: [Y coordinate for heal placement]
		RAGE_SPELL_X: [X coordinate for rage placement]
		RAGE_SPELL_Y: [Y coordinate for rage placement]
		JUMP_SPELL_X: [X coordinate for jump placement]
		JUMP_SPELL_Y: [Y coordinate for jump placement]

		**BOT_EXECUTION_SEQUENCE:** (launchtroop2 compatible)
		STEP_1: DEPLOY [number] [troop] AT_PIXEL [X,Y]
		STEP_2: WAIT [milliseconds]
		STEP_3: DEPLOY [number] [troop] AT_PIXEL [X,Y]
		STEP_4: DROP_SPELL [spell_type] AT_PIXEL [X,Y] WHEN [condition]
		STEP_5: DEPLOY_HERO [hero_type] AT_PIXEL [X,Y] WHEN [condition]

		**DEPLOYMENT_EDGE_ANALYSIS:**
		BEST_ATTACK_EDGE: [TOP/BOTTOM/LEFT/RIGHT]
		ATTACK_START_PIXEL: [X,Y coordinate on chosen edge]
		ATTACK_SPREAD_PIXELS: [List of 3-5 X,Y coordinates for troop spread]

		Analyze the base image and provide pixel coordinates that integrate directly with DropTroop.au3 and launchtroop2 functions.
		`;

		// Get bot-specific analysis
		const visionResult = await analyzeBaseImage(imageData, botVisionPrompt);
		const botAnalysis = visionResult.analysis;

		// Parse the structured output for bot consumption
		const botData = parseBotAnalysis(botAnalysis);

		res.json({
			success: true,
			botData: botData,
			rawAnalysis: botAnalysis,
			modelUsed: visionResult.modelUsed,
			timestamp: Date.now(),
		});
	} catch (error) {
		console.error("Bot analysis error:", error);
		res.status(500).json({
			success: false,
			error: "Failed to analyze base for bot",
			details: error.message,
		});
	}
});

// Helper function to parse bot analysis into structured data
function parseBotAnalysis(analysis) {
	const botData = {
		townHallLevel: extractValue(analysis, "TOWN_HALL_LEVEL"),
		baseType: extractValue(analysis, "BASE_TYPE"),
		recommendedStrategy: extractValue(analysis, "RECOMMENDED_STRATEGY"),

		// Pixel coordinates for deployment (DropTroop.au3 compatible)
		deploymentCoordinates: {
			primaryX: parseInt(extractValue(analysis, "PRIMARY_DEPLOY_X")) || 430,
			primaryY: parseInt(extractValue(analysis, "PRIMARY_DEPLOY_Y")) || 650,
			secondaryX: parseInt(extractValue(analysis, "SECONDARY_DEPLOY_X")) || 400,
			secondaryY: parseInt(extractValue(analysis, "SECONDARY_DEPLOY_Y")) || 80,
			wallBreakerX: parseInt(extractValue(analysis, "WALLBREAKER_X")) || 450,
			wallBreakerY: parseInt(extractValue(analysis, "WALLBREAKER_Y")) || 600,
		},

		// Target pixel locations for objectives
		targetPixels: {
			townHallX: parseInt(extractValue(analysis, "TOWN_HALL_X")) || 430,
			townHallY: parseInt(extractValue(analysis, "TOWN_HALL_Y")) || 366,
			darkElixirX: parseInt(extractValue(analysis, "DARK_ELIXIR_X")) || 430,
			darkElixirY: parseInt(extractValue(analysis, "DARK_ELIXIR_Y")) || 366,
			goldStorage1X:
				parseInt(extractValue(analysis, "GOLD_STORAGE_1_X")) || 350,
			goldStorage1Y:
				parseInt(extractValue(analysis, "GOLD_STORAGE_1_Y")) || 300,
			eagleArtilleryX:
				parseInt(extractValue(analysis, "EAGLE_ARTILLERY_X")) || 430,
			eagleArtilleryY:
				parseInt(extractValue(analysis, "EAGLE_ARTILLERY_Y")) || 366,
		},

		// Edge deployment points for different troop types
		edgeDeployment: {
			tankX: parseInt(extractValue(analysis, "TANK_DEPLOY_X")) || 430,
			tankY: parseInt(extractValue(analysis, "TANK_DEPLOY_Y")) || 670,
			dpsX: parseInt(extractValue(analysis, "DPS_DEPLOY_X")) || 430,
			dpsY: parseInt(extractValue(analysis, "DPS_DEPLOY_Y")) || 650,
			heroX: parseInt(extractValue(analysis, "HERO_DEPLOY_X")) || 450,
			heroY: parseInt(extractValue(analysis, "HERO_DEPLOY_Y")) || 630,
		},

		// Spell placement coordinates
		spellPixels: {
			healX: parseInt(extractValue(analysis, "HEAL_SPELL_X")) || 430,
			healY: parseInt(extractValue(analysis, "HEAL_SPELL_Y")) || 366,
			rageX: parseInt(extractValue(analysis, "RAGE_SPELL_X")) || 430,
			rageY: parseInt(extractValue(analysis, "RAGE_SPELL_Y")) || 366,
			jumpX: parseInt(extractValue(analysis, "JUMP_SPELL_X")) || 430,
			jumpY: parseInt(extractValue(analysis, "JUMP_SPELL_Y")) || 366,
		},

		// Attack edge analysis
		attackEdge: {
			bestEdge: extractValue(analysis, "BEST_ATTACK_EDGE") || "BOTTOM",
			startPixelX:
				parseInt(extractValue(analysis, "ATTACK_START_PIXEL")?.split(",")[0]) ||
				430,
			startPixelY:
				parseInt(extractValue(analysis, "ATTACK_START_PIXEL")?.split(",")[1]) ||
				670,
			spreadPixels: extractSpreadPixels(analysis),
		},

		// Execution sequence for launchtroop2
		executionSteps: extractBotSteps(analysis),

		// Raw analysis for debugging
		rawAnalysis: analysis,
	};

	return botData;
}

function extractValue(text, key) {
	const regex = new RegExp(`${key}:\\s*(.+?)(?=\\n|$)`, "i");
	const match = text.match(regex);
	return match ? match[1].trim() : "Unknown";
}

function extractSteps(text) {
	// This function is now replaced by extractBotSteps for better bot integration
	return extractBotSteps(text);
}

// Helper functions to extract specific data from AI responses
function extractBaseType(text) {
	const match = text.match(/base type[:\s]*([^.\n]+)/i);
	return match ? match[1].trim() : "Unknown";
}

function extractTownHallLevel(text) {
	const match =
		text.match(/town hall[^:]*level[:\s]*(\d+)/i) ||
		text.match(/th[:\s]*(\d+)/i);
	return match ? parseInt(match[1]) : 0;
}

function extractWeakPoints(text) {
	const match = text.match(/weak[^:]*:([^0-9]+)/i);
	return match ? match[1].trim().split(/[,\n]/).slice(0, 3) : [];
}

function extractStrategy(text) {
	const match = text.match(/strategy[:\s]*([^.\n]+)/i);
	return match ? match[1].trim() : "Standard attack";
}

function extractOptimalSides(text) {
	const match = text.match(/(\d+)\s*side/i);
	return match ? parseInt(match[1]) : 2;
}

function extractPriorityTargets(text) {
	const targets = text.match(/target[s]?[:\s]*([^.\n]+)/i);
	return targets
		? targets[1].trim().split(/[,\n]/).slice(0, 3)
		: ["Storages", "Defenses"];
}

function extractRiskLevel(text) {
	const risk = text.match(/risk[:\s]*(low|medium|high)/i);
	return risk ? risk[1].toLowerCase() : "medium";
}

function extractEntryPoints(text) {
	const entryMatches =
		text.match(/entry[^:]*:([^.]+)/i) ||
		text.match(/deploy[^:]*at[^:]*:([^.]+)/i);
	return entryMatches
		? entryMatches[1].trim().split(/[,\n]/).slice(0, 3)
		: ["Bottom side", "Left side"];
}

function extractDeploymentOrder(text) {
	const orderMatches =
		text.match(/deployment order[^:]*:([^.]+)/i) ||
		text.match(/first[^:]*:([^.]+)/i);
	return orderMatches
		? orderMatches[1].trim().split(/[,\n]/).slice(0, 5)
		: ["Giants first", "Wall Breakers", "Support troops"];
}

function extractWallBreakerTargets(text) {
	const wallMatches =
		text.match(/wall breaker[s]?[^:]*:([^.]+)/i) ||
		text.match(/wall[s]?[^:]*:([^.]+)/i);
	return wallMatches
		? wallMatches[1].trim().split(/[,\n]/).slice(0, 3)
		: ["Eastern walls", "Compartment walls"];
}

function extractHeroDeployment(text) {
	const heroMatches =
		text.match(/hero[^:]*deployment[^:]*:([^.]+)/i) ||
		text.match(/hero[s]?[^:]*timing[^:]*:([^.]+)/i);
	return heroMatches
		? heroMatches[1].trim()
		: "Deploy heroes after initial breach";
}

function extractSpellTiming(text) {
	const spellMatches =
		text.match(/spell[s]?[^:]*timing[^:]*:([^.]+)/i) ||
		text.match(/spell[s]?[^:]*usage[^:]*:([^.]+)/i);
	return spellMatches
		? spellMatches[1].trim().split(/[,\n]/).slice(0, 3)
		: ["Heal spell during push", "Rage for damage"];
}

function extractPathPlanning(text) {
	const pathMatches =
		text.match(/path[^:]*:([^.]+)/i) || text.match(/route[^:]*:([^.]+)/i);
	return pathMatches ? pathMatches[1].trim() : "Direct path to storages";
}

function extractTiming(text) {
	const timing = text.match(/timing[:\s]*([^.\n]+)/i);
	return timing ? timing[1].trim() : "immediate";
}

function extractFormation(text) {
	const formation = text.match(/formation[:\s]*([^.\n]+)/i);
	return formation ? formation[1].trim() : "spread";
}

function extractSupportTroops(text) {
	const support = text.match(/support[^:]*:([^.\n]+)/i);
	return support ? support[1].trim().split(",").slice(0, 3) : [];
}

function extractEffectiveness(text) {
	const effectiveness = text.match(/effectiveness[:\s]*(\d+)/i);
	return effectiveness ? parseInt(effectiveness[1]) : 7;
}

function extractPivotDecision(text) {
	return (
		text.toLowerCase().includes("pivot") ||
		text.toLowerCase().includes("change")
	);
}

function extractNextTroops(text) {
	const troops = text.match(/next[^:]*:([^.\n]+)/i);
	return troops ? troops[1].trim() : "Continue current deployment";
}

function extractTargetPriority(text) {
	const priority = text.match(/priority[^:]*:([^.\n]+)/i);
	return priority ? priority[1].trim().split(",").slice(0, 3) : [];
}

function extractSpellRecommendations(text) {
	const spells = text.match(/spell[s]?[^:]*:([^.\n]+)/i);
	return spells ? spells[1].trim().split(",").slice(0, 3) : [];
}

function extractHeroTiming(text) {
	const hero = text.match(/hero[^:]*:([^.\n]+)/i);
	return hero ? hero[1].trim() : "Hold for later";
}

function extractSuccessProbability(text) {
	const prob = text.match(/success[^:]*:?\s*(\d+)/i);
	return prob ? parseInt(prob[1]) : 70;
}

function extractStepByStepPlan(text) {
	// Look for numbered steps in the text
	const stepMatches = text.match(/(\d+\.?\s*[^.\n]+)/g);
	if (stepMatches) {
		return stepMatches
			.slice(0, 10)
			.map((step) => step.replace(/^\d+\.?\s*/, "").trim())
			.filter((step) => step.length > 10); // Filter out very short steps
	}

	// Fallback: look for tactical plan sections
	const tacticalMatches = text.match(/tactical plan[^:]*:([^0-9]+)/i);
	if (tacticalMatches) {
		return tacticalMatches[1]
			.trim()
			.split(/[,\n]/)
			.slice(0, 8)
			.map((step) => step.trim())
			.filter((step) => step.length > 5);
	}

	// Default plan if no specific steps found
	return [
		"Deploy tank troops to absorb damage",
		"Use Wall Breakers to create entry points",
		"Deploy damage dealers behind tanks",
		"Target priority defenses first",
		"Use spells to support main push",
		"Deploy heroes for core penetration",
	];
}

function extractTroopComposition(text) {
	// Extract troop numbers and types from AI response
	const troopMatches = text.match(/(\d+)\s*([a-zA-Z\s]+)/g);
	return troopMatches ? troopMatches.slice(0, 10) : [];
}

function extractSpellSelection(text) {
	const spells = text.match(/spell[s]?[^:]*:([^.\n]+)/i);
	return spells ? spells[1].trim().split(",").slice(0, 5) : [];
}

function extractHeroSelection(text) {
	const heroes = text.match(/hero[es]*[^:]*:([^.\n]+)/i);
	return heroes ? heroes[1].trim().split(",").slice(0, 3) : [];
}

function extractCCRequest(text) {
	const cc = text.match(/clan castle[^:]*:([^.\n]+)/i);
	return cc ? cc[1].trim() : "Dragons or Electro Dragons";
}

function extractExpectedStars(text) {
	const stars = text.match(/(\d+)\s*star/i);
	return stars ? parseInt(stars[1]) : 2;
}

function extractResourceGain(text) {
	const resources = text.match(/resource[s]?[^:]*:([^.\n]+)/i);
	return resources ? resources[1].trim() : "High potential";
}

function extractSuccessFactors(text) {
	const success = text.match(/worked[^:]*:([^0-9]+)/i);
	return success ? success[1].trim().split(/[,\n]/).slice(0, 3) : [];
}

function extractImprovementAreas(text) {
	const improvement = text.match(/improve[d]?[^:]*:([^0-9]+)/i);
	return improvement ? improvement[1].trim().split(/[,\n]/).slice(0, 3) : [];
}

function extractStrategyAdjustments(text) {
	const adjustments = text.match(/adjustment[s]?[^:]*:([^0-9]+)/i);
	return adjustments ? adjustments[1].trim().split(/[,\n]/).slice(0, 3) : [];
}

function extractDeploymentLessons(text) {
	const lessons = text.match(/deployment[^:]*:([^0-9]+)/i);
	return lessons ? lessons[1].trim().split(/[,\n]/).slice(0, 3) : [];
}

function extractPerformanceScore(text) {
	const score = text.match(/score[^:]*:?\s*(\d+)/i);
	return score ? parseInt(score[1]) : 7;
}

function extractFutureRecommendations(text) {
	const recommendations = text.match(/future[^:]*:([^.\n]+)/i);
	return recommendations
		? recommendations[1].trim().split(/[,\n]/).slice(0, 3)
		: [];
}

function extractSpreadPixels(text) {
	const spreadMatch = text.match(/ATTACK_SPREAD_PIXELS:\s*(.+?)(?=\n|$)/i);
	if (spreadMatch) {
		const coords = spreadMatch[1].match(/\[(\d+),(\d+)\]/g);
		if (coords) {
			return coords.map((coord) => {
				const [x, y] = coord
					.replace(/[\[\]]/g, "")
					.split(",")
					.map(Number);
				return { x, y };
			});
		}
	}
	// Default spread pixels for bottom edge attack
	return [
		{ x: 380, y: 670 },
		{ x: 430, y: 670 },
		{ x: 480, y: 670 },
	];
}

function extractBotSteps(text) {
	const steps = [];
	const stepMatches = text.match(/STEP_\d+:(.+?)(?=STEP_|\n\n|$)/g);
	if (stepMatches) {
		stepMatches.forEach((step, index) => {
			const cleanStep = step.replace(/STEP_\d+:\s*/, "").trim();

			// Parse pixel coordinates from steps
			const pixelMatch = cleanStep.match(/AT_PIXEL\s*\[?(\d+),(\d+)\]?/);
			const troopMatch = cleanStep.match(/DEPLOY\s*(\d+)\s*([A-Z\s]+)/);
			const waitMatch = cleanStep.match(/WAIT\s*(\d+)/);
			const spellMatch = cleanStep.match(/DROP_SPELL\s*([A-Z\s]+)/);

			const stepData = {
				stepNumber: index + 1,
				action: cleanStep,
				actionType: "unknown",
			};

			if (pixelMatch) {
				stepData.pixelX = parseInt(pixelMatch[1]);
				stepData.pixelY = parseInt(pixelMatch[2]);
			}

			if (troopMatch) {
				stepData.actionType = "deploy";
				stepData.troopCount = parseInt(troopMatch[1]);
				stepData.troopType = troopMatch[2].trim();
			} else if (waitMatch) {
				stepData.actionType = "wait";
				stepData.waitTime = parseInt(waitMatch[1]);
			} else if (spellMatch) {
				stepData.actionType = "spell";
				stepData.spellType = spellMatch[1].trim();
			}

			steps.push(stepData);
		});
	} else {
		// Default bot execution steps if none found
		steps.push(
			{
				stepNumber: 1,
				action: "DEPLOY 4 GIANTS AT_PIXEL [430,670]",
				actionType: "deploy",
				troopCount: 4,
				troopType: "GIANTS",
				pixelX: 430,
				pixelY: 670,
			},
			{
				stepNumber: 2,
				action: "WAIT 2000",
				actionType: "wait",
				waitTime: 2000,
			},
			{
				stepNumber: 3,
				action: "DEPLOY 3 WALL_BREAKERS AT_PIXEL [450,650]",
				actionType: "deploy",
				troopCount: 3,
				troopType: "WALL_BREAKERS",
				pixelX: 450,
				pixelY: 650,
			}
		);
	}
	return steps;
}

// Start the server
app.listen(PORT, () => {
	console.log(`🤖 AI Attack Analyzer server running on port ${PORT}`);
	console.log(`📍 Health check: http://localhost:${PORT}/health`);
	console.log(`🎯 Base Analysis: POST /api/analyze-base`);
	console.log(`⚔️ Deployment Optimizer: POST /api/optimize-deployment`);
	console.log(`🔄 Strategy Adaptation: POST /api/adapt-strategy`);
	console.log(`🏗️ Army Optimizer: POST /api/optimize-army`);
	console.log(`📊 Battle Learning: POST /api/learn-from-battle`);
	console.log(`🗺️ Visual Attack Planner: POST /api/plan-attack-visual`);
	console.log(`🤖 Bot Analysis: POST /api/bot-analyze`);
});

export default app;
