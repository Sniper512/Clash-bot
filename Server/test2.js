// import the Genkit and Google AI plugin libraries
import { gemini15Flash, googleAI } from "@genkit-ai/googleai";
import { genkit } from "genkit";
import dotenv from "dotenv";

// Load environment variables from .env.local file
dotenv.config({ path: ".env.local" });

// Check if the API key is loaded
console.log(
	"GOOGLE_API_KEY loaded:",
	process.env.GOOGLE_API_KEY ? "✓ Yes" : "✗ No"
);

// configure a Genkit instance
const ai = genkit({
	plugins: [googleAI()],
	model: gemini15Flash, // set default model
});

// Simple test without flow
async function testClashOfClans() {
	const message =
		"Tell me about Clash of Clans attack strategies and how AI could improve them";
	console.log("Sending prompt:", message);

	const { text } = await ai.generate(message);
	console.log("Response:", text);
}

testClashOfClans();
