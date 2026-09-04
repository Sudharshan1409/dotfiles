"""AI provider abstraction for `enigma ai`.

Three providers behind one interface: OpenAI, Google Gemini, Anthropic
Claude. Each provider takes a unified message list + JSON schema and
returns a parsed dict response (or an error string).

Unified message format (used everywhere in mai.py):
    [{"role": "user"|"assistant", "content": "<string>"}, ...]

Each provider's `call()` translates this to its native shape and converts
the structured output back into a Python dict.

Config persistence lives at ~/.cache/zsh/ai_config.json (per-machine, not
in the dotfiles repo). Env vars $AI_PROVIDER, $OPENAI_MODEL, $GEMINI_MODEL,
$ANTHROPIC_MODEL override file values when set.
"""
import json
import os
from pathlib import Path

CONFIG_PATH = Path.home() / ".cache" / "zsh" / "ai_config.json"


class Provider:
    """Base class. Subclasses fill in class-level metadata and call()."""
    key: str = ""
    name: str = ""
    api_key_env: str = ""
    setup_url: str = ""
    default_model: str = ""
    suggested_models: list = []
    package: str = ""  # pip package name, for friendlier import errors

    def create_client(self, api_key: str):
        raise NotImplementedError

    def call(self, client, model, contents, schema, system):
        """Return ("ok", dict) on success or ("error", str) on failure."""
        raise NotImplementedError


class OpenAIProvider(Provider):
    key = "openai"
    name = "OpenAI"
    api_key_env = "OPENAI_API_KEY"
    setup_url = "https://platform.openai.com/api-keys"
    default_model = "gpt-5"
    suggested_models = ["gpt-5", "gpt-5-mini", "gpt-4.1", "gpt-4o", "o3", "o3-mini"]
    package = "openai"

    def create_client(self, api_key):
        from openai import OpenAI
        return OpenAI(api_key=api_key)

    def call(self, client, model, contents, schema, system):
        msgs = [{"role": "system", "content": system}]
        for c in contents:
            msgs.append({"role": c["role"], "content": c["content"]})
        try:
            response = client.chat.completions.create(
                model=model,
                messages=msgs,
                response_format={
                    "type": "json_schema",
                    "json_schema": {"name": "response", "schema": schema},
                },
                temperature=0.2,
            )
        except Exception as e:
            return ("error", str(e))
        try:
            return ("ok", json.loads(response.choices[0].message.content))
        except (json.JSONDecodeError, AttributeError, IndexError) as e:
            return ("error", f"Could not parse response as JSON: {e}")


class GeminiProvider(Provider):
    key = "gemini"
    name = "Google Gemini"
    api_key_env = "GEMINI_API_KEY"
    setup_url = "https://aistudio.google.com/apikey"
    default_model = "gemini-3.1-pro-preview"
    suggested_models = [
        "gemini-3.1-pro-preview",
        "gemini-2.5-pro",
        "gemini-2.5-flash",
    ]
    package = "google-genai"

    def create_client(self, api_key):
        from google import genai
        return genai.Client(api_key=api_key)

    def call(self, client, model, contents, schema, system):
        from google.genai import types
        # Convert unified format -> Gemini (assistant => "model")
        gem_contents = []
        for c in contents:
            role = "model" if c["role"] == "assistant" else "user"
            gem_contents.append({"role": role, "parts": [{"text": c["content"]}]})
        config = types.GenerateContentConfig(
            system_instruction=system,
            response_mime_type="application/json",
            response_schema=schema,
            temperature=0.2,
        )
        try:
            response = client.models.generate_content(
                model=model, contents=gem_contents, config=config,
            )
        except Exception as e:
            return ("error", str(e))
        try:
            return ("ok", json.loads(response.text))
        except (json.JSONDecodeError, AttributeError) as e:
            return ("error", f"Could not parse response as JSON: {e}")


class AnthropicProvider(Provider):
    key = "anthropic"
    name = "Anthropic Claude"
    api_key_env = "ANTHROPIC_API_KEY"
    setup_url = "https://console.anthropic.com/settings/keys"
    default_model = "claude-opus-4-7"
    suggested_models = [
        "claude-opus-4-7",
        "claude-sonnet-4-6",
        "claude-haiku-4-5-20251001",
    ]
    package = "anthropic"

    def create_client(self, api_key):
        from anthropic import Anthropic
        return Anthropic(api_key=api_key)

    def call(self, client, model, contents, schema, system):
        # Anthropic uses tool_use blocks for guaranteed structured output.
        msgs = [{"role": c["role"], "content": c["content"]} for c in contents]
        try:
            response = client.messages.create(
                model=model,
                system=system,
                tools=[{
                    "name": "respond",
                    "description": "Respond to the user with structured JSON.",
                    "input_schema": schema,
                }],
                tool_choice={"type": "tool", "name": "respond"},
                messages=msgs,
                max_tokens=4096,
                temperature=0.2,
            )
        except Exception as e:
            return ("error", str(e))
        for block in response.content:
            if getattr(block, "type", None) == "tool_use":
                return ("ok", block.input)
        return ("error", "No tool_use block in Claude response")


PROVIDERS = {
    p.key: p()
    for p in (OpenAIProvider, GeminiProvider, AnthropicProvider)
}


def _default_config():
    return {
        "provider": "gemini",
        "models": {p.key: p.default_model for p in PROVIDERS.values()},
    }


def load_config():
    """Load config file; fill in defaults for any missing fields."""
    default = _default_config()
    if not CONFIG_PATH.exists():
        return default
    try:
        with open(CONFIG_PATH) as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return default
    if data.get("provider") not in PROVIDERS:
        data["provider"] = default["provider"]
    models = default["models"].copy()
    models.update(data.get("models") or {})
    data["models"] = models
    return data


def save_config(config):
    """Atomic write — same pattern as lib.common.write_registry."""
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = CONFIG_PATH.with_suffix(".tmp")
    with open(tmp, "w") as f:
        json.dump(config, f, indent=2, sort_keys=True)
    tmp.replace(CONFIG_PATH)


_MODEL_ENV = {
    "openai": "OPENAI_MODEL",
    "gemini": "GEMINI_MODEL",
    "anthropic": "ANTHROPIC_MODEL",
}


def resolve(config):
    """Apply env-var overrides on top of file config.

    Returns (provider_instance, model_id). $AI_PROVIDER picks the provider;
    $<PROVIDER>_MODEL overrides that provider's model.
    """
    provider_key = os.environ.get("AI_PROVIDER", "").lower() or config["provider"]
    if provider_key not in PROVIDERS:
        provider_key = config["provider"]
    provider = PROVIDERS[provider_key]
    model = config["models"].get(provider_key, provider.default_model)
    override = os.environ.get(_MODEL_ENV[provider_key])
    if override:
        model = override
    return provider, model
