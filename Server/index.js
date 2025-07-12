// Firebase Genkit server for AI-generated attack strategies
import { config } from "dotenv";
import { gemini15Flash, googleAI } from "@genkit-ai/googleai";
import { genkit } from "genkit";
import express from "express";
import cors from "cors";

// Load environment variables from .env.local
config({ path: ".env.local" });

// Configure Genkit instance
const ai = genkit({
	plugins: [googleAI()],
	model: gemini15Flash,
});

// Create Express app
const app = express();
app.use(cors());
app.use(express.json());

// Fallback strategy when AI is unavailable
function createFallbackStrategy(nbSides = 4) {
	return [
		["$eGiant", nbSides, 1, 1, 2], // Giants with 2 slots per edge
		["$eWall", nbSides, 1, 1, 1], // Wall breakers with 1 slot per edge
		["$eBarb", nbSides, 1, 1, 0], // Barbarians spread deployment
		["$eArch", nbSides, 1, 1, 0], // Archers spread deployment
		["HEROES", 1, 2, 1, 1], // Heroes: 1 side, wave 2, max 1 wave, 1 slot
		["CC", 1, 1, 1, 1], // CC: 1 side, wave 1, max 1 wave, 1 slot
	];
}

// Log all incoming requests
app.use((req, res, next) => {
	console.log(
		`🌐 Incoming ${req.method} request to ${req.path} from ${req.ip}`
	);
	console.log(`📅 Time: ${new Date().toISOString()}`);
	if (Object.keys(req.query).length > 0) {
		console.log(`❓ Query params:`, req.query);
	}
	if (req.body && Object.keys(req.body).length > 0) {
		console.log(`📦 Body:`, JSON.stringify(req.body, null, 2));
	}
	next();
});

// Define the strategy generation flow
const generateStrategyFlow = ai.defineFlow(
	"generateStrategy",
	async (input) => {
		const { matchMode, dropOrder, nbSides, availableTroops, targetInfo } =
			input;

		const prompt = `
Generate a Clash of Clans attack strategy for the following parameters:
- Match Mode: ${matchMode} (0=All troops, 1=Barcher only, 2=Giant+Barcher)
- Drop Order: ${dropOrder}
- Number of sides to attack: ${nbSides}
- Available troops: ${JSON.stringify(availableTroops)}
- Target info: ${JSON.stringify(targetInfo)}

You must return ONLY a valid JSON array where each element follows this exact format:
[troopType, numberOfSides, waveNumber, maxWaveNumber, slotsPerEdge]

Where:
- troopType: Use these exact constants: $eBarb, $eArch, $eGiant, $eGobl, $eWiza, $eBall, $eWall, $eLoon, $eDrag, $ePekk, $eBabyD, $eMine, $eEDrag, $eYeti, $eDragR, $eElem, $eHeal, $eLava, $eBowl, $eIceG, $eHunt, $eAppW, $eDruid, $eFurn, "CC", "HEROES"
- numberOfSides: Use the number ${nbSides} for regular troops, use the number 1 for CC and HEROES
- waveNumber: Deployment wave (1=first wave, 2=second wave, etc.)
- maxWaveNumber: Total waves for this troop type (usually 1)
- slotsPerEdge: 0=spread along edge, 1+=specific number of deployment points per edge

CRITICAL RULES:
- CC (Clan Castle) should always use: ["CC", 1, 1, 1, 1]
- HEROES should always use: ["HEROES", 1, 2, 1, 1] (deploy in wave 2)
- Tank troops (Giants, Golems): Use 2-4 slots per edge
- Wall breakers: Use 1 slot per edge  
- DPS troops (Barb, Arch): Use 0 for spread deployment
- Deploy order: Tanks first (wave 1), then support troops, heroes later (wave 2+)
- NEVER use "undefined" values - always use actual numbers
- numberOfSides must be ${nbSides} for regular troops (NOT undefined)

Example response format (COPY THIS EXACT STRUCTURE):
[
    ["$eGiant", ${nbSides}, 1, 1, 2],
    ["$eWall", ${nbSides}, 1, 1, 1], 
    ["$eBarb", ${nbSides}, 1, 1, 0],
    ["$eArch", ${nbSides}, 1, 1, 0],
    ["CC", 1, 1, 1, 1],
    ["HEROES", 1, 2, 1, 1]
]

Return ONLY the JSON array with NO markdown formatting, NO backticks, NO extra text.
`;

		console.log("\n--- New Strategy Generation Request ---");
		console.log("Received input:", JSON.stringify(input, null, 2));

		const { text } = await ai.generate(prompt);
		console.log("Raw AI response:", text);
		console.log("Response length:", text.length);

		let strategy;

		try {
			// Try to parse the response as JSON
			console.log("Attempting direct JSON parse...");
			strategy = JSON.parse(text);
			console.log("Direct JSON parse successful!");
		} catch (error) {
			console.log("Direct JSON parse failed:", error.message);
			console.log("Attempting to extract JSON from text...");
			// Remove markdown formatting if present
			let cleanText = text
				.replace(/```json/g, "")
				.replace(/```/g, "")
				.trim();

			// Try to find and extract the JSON array
			const jsonMatch = cleanText.match(/\[[\s\S]*\]/);
			if (jsonMatch) {
				console.log(
					"Found JSON pattern in text:",
					jsonMatch[0].substring(0, 100) + "..."
				);
				try {
					// Clean up any 'undefined' values that might appear
					let cleanJson = jsonMatch[0].replace(/undefined/g, "4"); // Replace undefined with 4 (default nbSides)
					strategy = JSON.parse(cleanJson);
					console.log("Extracted JSON parse successful!");
				} catch (innerError) {
					console.error("Extracted JSON parse failed:", innerError.message);
					return null; // Return null on failure
				}
			} else {
				console.error("No JSON pattern found in AI response");
				return null; // Return null on failure
			}
		}

		// Final validation: Ensure the result is a non-empty array of arrays
		console.log("Validating strategy structure...");
		console.log("Strategy is array:", Array.isArray(strategy));
		console.log("Strategy length:", strategy ? strategy.length : "undefined");
		console.log(
			"First element is array:",
			strategy && strategy.length > 0
				? Array.isArray(strategy[0])
				: "no first element"
		);
		if (
			Array.isArray(strategy) &&
			strategy.length > 0 &&
			Array.isArray(strategy[0])
		) {
			console.log("Strategy validation passed!");
			console.log("Final strategy:", JSON.stringify(strategy, null, 2));
			return strategy; // Return only the strategy array
		} else {
			console.error("Strategy validation failed!");
			console.error("Strategy:", strategy);
			// If validation fails, return null
			return null;
		}
	}
);

// API endpoint to generate strategy
app.post("/api/generate-strategy", async (req, res) => {
	console.log(`\n[${new Date().toISOString()}] POST /api/generate-strategy`);
	console.log("Request body:", JSON.stringify(req.body, null, 2));

	try {
		const strategy = await generateStrategyFlow(req.body);
		console.log("Sending strategy to bot:", JSON.stringify(strategy, null, 2));

		if (strategy) {
			console.log(
				"✅ API Response: Sending strategy array with",
				strategy.length,
				"entries"
			);
			console.log("📤 Exact response being sent:", JSON.stringify(strategy));
			res.json(strategy); // Send only the strategy array
		} else {
			console.log(
				"❌ API Response: Strategy generation failed, using fallback strategy"
			);
			const fallbackStrategy = createFallbackStrategy(req.body.nbSides || 4);
			console.log(
				"📤 Exact response being sent:",
				JSON.stringify(fallbackStrategy)
			);
			res.json(fallbackStrategy); // Send fallback strategy instead of empty array
		}
	} catch (error) {
		console.error("Error generating strategy:", error);
		console.log("💥 API Response: Exception occurred, using fallback strategy");
		const fallbackStrategy = createFallbackStrategy(req.body.nbSides || 4);
		console.log(
			"📤 Exact response being sent:",
			JSON.stringify(fallbackStrategy)
		);
		res.json(fallbackStrategy); // Send fallback strategy instead of empty array
	}
});

// Health check endpoint
app.get("/api/health", (req, res) => {
	res.json({ status: "OK", message: "Genkit server is running" });
});

// Test endpoint with mock strategy (for testing without API key)
app.post("/api/test-strategy", (req, res) => {
	console.log(`\n[${new Date().toISOString()}] POST /api/test-strategy`);
	try {
		const { matchMode, dropOrder, nbSides, availableTroops, targetInfo } =
			req.body;

		// Mock strategy response for testing
		const mockStrategy = [
			["$eGiant", 2, 1, 1, 4],
			["$eWall", 2, 1, 1, 1],
			["$eBarb", 2, 1, 1, 0],
			["$eArch", 2, 1, 1, 0],
			["CC", 1, 1, 1, 1],
			["HEROES", 1, 2, 1, 1],
		];

		console.log(
			"🧪 Test API Response: Sending mock strategy with",
			mockStrategy.length,
			"entries"
		);
		console.log(
			"📤 Exact test response being sent:",
			JSON.stringify(mockStrategy)
		);
		res.json(mockStrategy); // Send only the strategy array
	} catch (error) {
		console.error("Error in test endpoint:", error);
		console.log(
			"💥 Test API Response: Exception occurred, sending error object"
		);
		res.status(500).json({
			success: false,
			error: "Test endpoint error",
			details: error.message,
		});
	}
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
	console.log(`🚀 Server running on port ${PORT}`);
	console.log(`📍 Health check: http://localhost:${PORT}/api/health`);
	console.log(
		`🎯 Strategy endpoint: http://localhost:${PORT}/api/generate-strategy`
	);
	console.log(`🧪 Test endpoint: http://localhost:${PORT}/api/test-strategy`);
	console.log(`⏰ Server started at: ${new Date().toISOString()}`);
	console.log("🔍 Waiting for requests...\n");
});

export default app;
