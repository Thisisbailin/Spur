/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run "npm run dev" in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run "npm run deploy" to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

// 使用 ES Modules 语法
export default {
  /**
   * Handles incoming requests and routes based on URL path.
   * @param {Request} request - The incoming request object.
   * @param {object} env - Environment variables and secrets.
   * @param {ExecutionContext} ctx - Execution context.
   * @returns {Promise<Response>}
   */
  async fetch(request, env, ctx) {
    console.log(`RELAY ESM Received request: ${request.method} ${request.url}`);
    const apiKey = env.GEMINI_API_KEY;
    if (!apiKey) {
      return this.errorResponse("API Key not configured", 500);
    }

    const url = new URL(request.url);
    const pathname = url.pathname;

    try {
      if (request.method !== 'POST') {
        return this.errorResponse("Method Not Allowed, expecting POST", 405);
      }

      // --- Routing based on path ---
      if (pathname === '/ocr') {
        console.log("Routing to OCR handler...");
        return await this.handleOcrRequest(request, apiKey);
      } else if (pathname === '/define') {
        console.log("Routing to Definition handler...");
        return await this.handleDefineRequest(request, apiKey);
      } else {
        console.log(`Unknown path: ${pathname}`);
        return this.errorResponse("Not Found - Endpoint active, but path unknown.", 404);
      }
      // --- End Routing ---

    } catch (error) {
      console.error("RELAY ESM Unhandled Worker Error:", error);
      return this.errorResponse(`Worker relay error: ${error.message || error}`, 503);
    }
  },

  // --- OCR Request Handler ---
  async handleOcrRequest(request, apiKey) {
    const modelName = "gemini-2.0-flash"; // Consistent model
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

    let incomingPayload;
    try {
      incomingPayload = await request.json();
    } catch (e) {
      console.error("OCR Handler: Error parsing incoming JSON:", e);
      return this.errorResponse("Invalid JSON body received from client", 400);
    }

    if (!incomingPayload || !incomingPayload.userContent || !Array.isArray(incomingPayload.userContent) || incomingPayload.userContent.length === 0) {
      console.error("OCR Handler: Missing or invalid 'userContent' in incoming payload.");
      return this.errorResponse("Missing or invalid userContent in request body", 400);
    }
    // Basic check for inlineData within the first part
     if (!incomingPayload.userContent[0]?.parts?.some(p => p.inlineData?.data)) {
         console.error("OCR Handler: Missing 'inlineData' in userContent parts.");
         return this.errorResponse("Missing image data (inlineData) in request", 400);
     }

    const geminiApiPayload = {
      contents: incomingPayload.userContent,
      ...(incomingPayload.systemInstruction && { systemInstruction: { parts: [{ text: incomingPayload.systemInstruction }] } }),
      // Add generationConfig etc. if needed
    };

    console.log(`OCR Handler: Forwarding to Gemini (${modelName})...`);
    return await this.makeGeminiRequest(geminiUrl, geminiApiPayload);
  },

  // --- Definition Request Handler ---
  async handleDefineRequest(request, apiKey) {
    const modelName = "gemini-2.0-flash"; // Or choose another appropriate model
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

    let incomingPayload;
    try {
      incomingPayload = await request.json();
      console.log("Define Handler: Parsed incoming payload.");
    } catch (e) {
      console.error("Define Handler: Error parsing incoming JSON:", e);
      return this.errorResponse("Invalid JSON body received from client", 400);
    }

    // Validate payload for definition request
    if (!incomingPayload || !incomingPayload.userContent || !Array.isArray(incomingPayload.userContent) || incomingPayload.userContent.length === 0 || !incomingPayload.userContent[0]?.parts?.[0]?.text) {
      console.error("Define Handler: Missing or invalid 'userContent' (expected text part) in incoming payload.");
      return this.errorResponse("Missing or invalid word text in request body", 400);
    }
    if (!incomingPayload.systemInstruction) {
         console.error("Define Handler: Missing 'systemInstruction' in incoming payload.");
         return this.errorResponse("Missing systemInstruction in request body", 400);
    }

    // Construct the payload for Gemini API (it matches the incoming structure)
    const geminiApiPayload = {
      contents: incomingPayload.userContent,
      systemInstruction: { parts: [{ text: incomingPayload.systemInstruction }] },
      // Optionally add generationConfig here if needed and forwarded by client
      // generationConfig: { ... }
    };

    console.log(`Define Handler: Forwarding definition request to Gemini (${modelName})...`);
    // Use the existing helper function to make the call
    return await this.makeGeminiRequest(geminiUrl, geminiApiPayload);
  },

  // --- Helper: Make Gemini API Request ---
  async makeGeminiRequest(url, payload) {
    const headers = new Headers({ 'Content-Type': 'application/json' });
    const fetchOptions = {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(payload),
    };

    console.log(`Making Gemini request to: ${url}`);
    // console.log("Payload:", JSON.stringify(payload).substring(0, 300) + "..."); // Log partial payload for debug

    const geminiResponse = await fetch(url, fetchOptions);
    console.log(`Received response from Gemini with status: ${geminiResponse.status}`);

    // Forward the response, adding CORS header
    const responseHeaders = new Headers(geminiResponse.headers);
    responseHeaders.set('Access-Control-Allow-Origin', '*'); // Adjust as needed

    return new Response(geminiResponse.body, {
      status: geminiResponse.status,
      statusText: geminiResponse.statusText,
      headers: responseHeaders,
    });
  },

  // --- Helper: Error Response ---
  errorResponse(message, status) {
    return new Response(JSON.stringify({ error: message }), {
      status: status,
      headers: { 
          'Content-Type': 'application/json',
           'Access-Control-Allow-Origin': '*' // Also add CORS to error responses
       }
    });
  }
};
