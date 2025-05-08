import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from typing import Optional

load_dotenv()

class HatchChatbot:
    def __init__(self):
        self.client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
        self.model = "gemini-2.5-pro-exp-03-25"
        self.system_instruction = """You are a helpful and context-aware chatbot in a community collaboration app called Hatch. Assist users in navigating their communities, managing tasks, and communicating with others. Help them join or leave communities, send messages to individuals or channels, and assign or view tasks. Always understand the context of the user's current community and respond accordingly. Keep your responses clear, concise, and action-oriented. Your goal is to enhance collaboration and boost productivity within the platform."""

    def generate(self, prompt: str) -> Optional[str]:
        try:
            contents = [
                types.Content(
                    role="user",
                    parts=[types.Part.from_text(text=prompt)],
                ),
            ]
            
            generate_content_config = types.GenerateContentConfig(
                system_instruction=[
                    types.Part.from_text(text=self.system_instruction),
                ],
            )

            response = self.client.models.generate_content(
                model=self.model,
                contents=contents,
                config=generate_content_config,
            )
            
            return response.text

        except Exception as e:
            print(f"Error generating response: {str(e)}")
            return None

hatch_chatbot = HatchChatbot()

