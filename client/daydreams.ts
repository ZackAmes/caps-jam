import {
    createContainer,
    createDreams,
    createMemoryStore,
    LogLevel,
    validateEnv,
  } from "@daydreamsai/core";
  import { createChromaVectorStore } from "@daydreamsai/chromadb";
  import { z } from "zod";
  import { google } from "@ai-sdk/google";
  import { discord } from "@daydreamsai/discord";
  // Validate environment before proceeding
  const env = validateEnv(
    z.object({
      GOOGLE_GENERATIVE_AI_API_KEY: z.string().min(1, "GOOGLE_GENERATIVE_API_KEY is required"),
    })
  );


  
  const container = createContainer();

  const agent = createDreams({
    model: google("gemini-2.0-flash-001"),
    container,
    extensions: [discord],
    memory: {
      store: createMemoryStore(),
      vector: createChromaVectorStore("agent", "http://localhost:8000"),
      vectorModel: google("gemini-2.0-flash-001"),
    },
  });
  
  console.log("Starting Daydreams Discord Bot...");
  await agent.start();
  console.log("Daydreams Discord Bot started");