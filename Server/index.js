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
[troopType, nbSides, waveNumber, maxWaveNumber, slotsPerEdge]

Where:
- troopType: Use these exact constants: $eBarb, $eSBarb, $eArch, $eSArch, $eGiant, $eSGiant, $eGobl, $eSGobl, $eWall, $eSWall, $eBall, $eRBall, $eWiza, $eSWiza, $eHeal, $eDrag, $eSDrag, $ePekk, $eBabyD, $eInfernoD, $eMine, $eSMine, $eEDrag, $eYeti, $eRDrag, $eETitan, $eRootR, $eThrower, $eMini, $eSMini, $eHogs, $eSHogs, $eValk, $eSValk, $eGole, $eWitc, $eSWitc, $eLava, $eIceH, $eBowl, $eSBowl, $eIceG, $eHunt, $eAppWard, $eDruid, $eFurn, "CC", "HEROES"
- nbSides: Number of sides to deploy on (use the provided nbSides value)
- waveNumber: The wave number for this troop deployment (1, 2, 3, etc.)
- maxWaveNumber: Maximum waves for this troop type
- slotsPerEdge: Number of slots per edge (0 for spread deployment, 1+ for specific slots)

Example response format:
[
    ["$eGiant", ${nbSides}, 1, 1, 2],
    ["$eSGiant", ${nbSides}, 1, 1, 2],
    ["CC", 1, 1, 1, 1],
    ["$eBarb", ${nbSides}, 1, 2, 0],
    ["$eSBarb", ${nbSides}, 1, 2, 0],
    ["$eWall", ${nbSides}, 1, 1, 1],
    ["$eSWall", ${nbSides}, 1, 1, 1],
    ["$eArch", ${nbSides}, 1, 2, 0],
    ["$eSArch", ${nbSides}, 1, 2, 0],
    ["HEROES", 1, 2, 1, 1]
]

Create an optimal strategy based on the input parameters. Consider:
- Deploy tank troops (Giants, Golems) first
- Follow with wall breakers if needed
- Deploy damage dealers (Archers, Barbarians) after tanks
- Save heroes for mid-battle
- Use CC troops strategically
- Adapt wave numbers and slots based on the attack complexity

Return ONLY the JSON array, no additional text or explanation.
`;

		const { text } = await ai.generate(prompt);

		try {
			// Try to parse the response as JSON
			const strategy = JSON.parse(text);
			return { success: true, strategy };
		} catch (error) {
			// If JSON parsing fails, try to extract JSON from the text
			const jsonMatch = text.match(/\[[\s\S]*\]/);
			if (jsonMatch) {
				try {
					const strategy = JSON.parse(jsonMatch[0]);
					return { success: true, strategy };
				} catch (innerError) {
					return {
						success: false,
						error: "Failed to parse AI response as JSON",
						rawResponse: text,
					};
				}
			}
			return {
				success: false,
				error: "No valid JSON found in AI response",
				rawResponse: text,
			};
		}
	}
);

// API endpoint to generate strategy
app.post("/api/generate-strategy", async (req, res) => {
	try {
		const result = await generateStrategyFlow(req.body);
		res.json(result);
	} catch (error) {
		console.error("Error generating strategy:", error);
		res.status(500).json({
			success: false,
			error: "Internal server error",
			details: error.message,
		});
	}
});

// Health check endpoint
app.get("/api/health", (req, res) => {
	res.json({ status: "OK", message: "Genkit server is running" });
});

// Test endpoint with mock strategy (for testing without API key)
app.post("/api/test-strategy", (req, res) => {
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

		res.json({
			success: true,
			strategy: mockStrategy,
			message: "Mock strategy generated for testing",
			input: { matchMode, dropOrder, nbSides, availableTroops, targetInfo },
		});
	} catch (error) {
		console.error("Error in test endpoint:", error);
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
	console.log(`Server running on port ${PORT}`);
});

export default app;
