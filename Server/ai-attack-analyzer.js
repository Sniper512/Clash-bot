// AI Attack Analyzer - Genkit-powered functions for Clash of Clans bot
import { gemini15Flash, googleAI } from "@genkit-ai/googleai";
import { genkit } from "genkit";
import dotenv from "dotenv";
import express from "express";
import cors from "cors";

// Load environment variables
dotenv.config({ path: ".env.local" });

// Initialize Genkit
const ai = genkit({
	plugins: [googleAI()],
	model: gemini15Flash,
});

// Initialize Express app
const app = express();
app.use(cors());
app.use(express.json({ limit: "50mb" }));

const PORT = process.env.PORT || 3000;

// Health check endpoint
app.get("/health", (req, res) => {
	res.json({ status: "ok", message: "AI Attack Analyzer is running" });
});

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

		const prompt = `
		You are an expert Clash of Clans attack strategist. ${
			baseImage
				? "Analyze this base layout image"
				: "Analyze this base layout description"
		} and provide strategic recommendations.
		
		Available troops: ${troopComposition || "Standard army composition"}
		Target resources: ${targetResources || "Gold, Elixir, Dark Elixir"}
		
		${
			!baseImage
				? `
		Base Layout Description:
		- Layout: ${baseLayout || "Unknown layout"}
		- Defense Positions: ${
			defensePositions
				? defensePositions.join(", ")
				: "Standard defense placement"
		}
		- Wall Configuration: ${wallConfiguration || "Standard wall setup"}
		`
				: ""
		}
		
		${
			baseImage
				? "Please analyze the base image and provide a detailed attack plan:"
				: "Based on the base description provided, provide a detailed attack plan:"
		}
		
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
		
		Provide specific, actionable recommendations based on what you see in the image. Focus on creating a step-by-step attack plan that maximizes success with the given army composition.
		
		Format your response as clear, structured text with specific coordinates or directions where possible (e.g., "Deploy Giants at bottom-left corner", "Place Wall Breakers near the eastern wall section").
		`;

		// Prepare the image data for Gemini Vision
		let imageData = null;
		if (baseImage.startsWith("data:image/")) {
			// Handle base64 encoded images
			const base64Data = baseImage.split(",")[1];
			imageData = {
				inlineData: {
					data: base64Data,
					mimeType: baseImage.split(";")[0].split(":")[1],
				},
			};
		} else {
			// Handle image URLs or file paths
			imageData = {
				fileData: {
					fileUri: baseImage,
					mimeType: "image/png",
				},
			};
		}

		let generationResult;

		if (baseImage) {
			// Generate analysis with image input
			generationResult = await ai.generate({
				prompt: prompt,
				media: imageData,
			});
		} else {
			// Generate analysis with text input only
			generationResult = await ai.generate({
				prompt: prompt,
			});
		}

		const { text } = generationResult;

		// Parse AI response and structure it with enhanced vision analysis
		const analysis = {
			baseType: extractBaseType(text),
			townHallLevel: extractTownHallLevel(text),
			weakPoints: extractWeakPoints(text),
			recommendedStrategy: extractStrategy(text),
			optimalSides: extractOptimalSides(text),
			priorityTargets: extractPriorityTargets(text),
			riskLevel: extractRiskLevel(text),
			entryPoints: extractEntryPoints(text),
			deploymentOrder: extractDeploymentOrder(text),
			wallBreakerTargets: extractWallBreakerTargets(text),
			heroDeployment: extractHeroDeployment(text),
			spellTiming: extractSpellTiming(text),
			pathPlanning: extractPathPlanning(text),
			successProbability: extractSuccessProbability(text),
			expectedStars: extractExpectedStars(text),
			stepByStepPlan: extractStepByStepPlan(text),
			fullAnalysis: text,
		};

		res.json({
			success: true,
			analysis: analysis,
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
});

export default app;
