#!/usr/bin/env python3
"""Enigma AI: natural-language shell command assistant.

Multi-provider (OpenAI / Gemini / Anthropic). Switch with `enigma ai config`
or env vars ($AI_PROVIDER, $OPENAI_MODEL, $GEMINI_MODEL, $ANTHROPIC_MODEL).

Flow per turn:
  1. Gather context (OS, pwd, git, ls, recent history).
  2. Send to the active provider with a JSON schema that forces one of three
     shapes: questions | commands | answer.
  3. If questions: prompt the user (multi-choice + custom), feed back.
  4. If commands: confirm each, run via zsh -c, stream output, feed result
     back so the AI can react.
  5. If answer: render markdown, loop for follow-up.

Multi-turn loop lives entirely inside one invocation — no cross-session
state besides the per-machine config in ~/.cache/zsh/ai_config.json.
"""
import argparse
import json
import os
import platform
import subprocess
import sys

from InquirerPy import inquirer
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel
from rich.syntax import Syntax
from rich.table import Table
from rich.text import Text

from lib.common import STYLE, prompt_with_interrupt_handler
from lib.ai_providers import PROVIDERS, load_config, save_config, resolve

CONSOLE = Console(stderr=True)

MAX_HISTORY_LINES = 20
MAX_DIR_ENTRIES = 40
MAX_OUTPUT_FEEDBACK = 4000

RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "kind": {
            "type": "string",
            "enum": ["questions", "commands", "answer"],
        },
        "reasoning": {
            "type": "string",
            "description": "One short sentence: what you understood and why this shape.",
        },
        "questions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "text": {"type": "string"},
                    "options": {"type": "array", "items": {"type": "string"}},
                    "allow_custom": {"type": "boolean"},
                },
                "required": ["text", "options", "allow_custom"],
            },
        },
        "plan": {
            "type": "string",
            "description": "One-line summary of the command plan.",
        },
        "commands": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "description": {"type": "string"},
                    "command": {"type": "string"},
                    "danger": {
                        "type": "string",
                        "enum": ["safe", "caution", "destructive"],
                    },
                    "purpose": {
                        "type": "string",
                        "enum": ["execute", "gather_info"],
                    },
                },
                "required": ["description", "command", "danger", "purpose"],
            },
        },
        "answer": {"type": "string"},
    },
    "required": ["kind", "reasoning"],
}


SYSTEM_PROMPT = """You are Enigma AI, a shell assistant embedded in a user's zsh CLI. You help the user accomplish tasks by proposing shell commands they execute.

## Hard rules

1. Output JSON matching the provided schema. No prose outside the schema.

2. Pick ONE response kind per turn:
   - `questions`: ask ONLY if real ambiguity would lead to the wrong command. Never ask for the sake of asking. "show running docker containers" needs zero questions. "compress my photos" needs questions (which dir? what format? quality?).
   - `commands`: propose a sequence the user will confirm and run. After execution, you'll see the output and can propose more.
   - `answer`: pure info reply when no commands are needed (e.g. "what does xargs -I do?").

3. For `commands`:
   - One shell line each. Multi-step only via `;` / `&&` when truly atomic.
   - `danger`:
     - `safe`: read-only (ls, cat, git status, ps, grep, find without -delete)
     - `caution`: writes user-space files (mv, mkdir, git commit, sed -i)
     - `destructive`: rm, sudo anything, force-push, drops/wipes, network changes
   - `purpose`:
     - `gather_info`: you need this output to decide next steps. MUST be `safe`. After the user runs it you'll get the output and continue.
     - `execute`: the actual work the user asked for.
   - Prefer modern tools the user has: `eza` `fd` `rg` `bat` `fzf` `gh` `zoxide`.
   - Don't assume `sudo`; if root is needed, say so in `description` and propose without sudo first when there's a userspace alternative.

4. For `questions`:
   - 2-4 multi-choice `options`. Set `allow_custom: true` if a custom answer is plausible.
   - Max 3 questions per turn. One is usually right.

5. `reasoning`: one short sentence on what you understood. Catches misinterpretation early.

## Context format

Each user turn may start with a `<context>` block (OS, shell, pwd, git, recent history, ls). Use it; don't echo it back."""


# ---------- Context gathering ----------

def get_context():
    ctx = {}
    ctx["platform"] = platform.platform()
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    ctx["distro"] = line.split("=", 1)[1].strip().strip('"')
                    break
    except OSError:
        pass
    ctx["shell"] = os.environ.get("SHELL", "unknown")
    ctx["cwd"] = os.getcwd()

    try:
        inside = subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            capture_output=True, text=True, timeout=2,
        )
        if inside.returncode == 0:
            ctx["git_repo"] = True
            branch = subprocess.run(
                ["git", "branch", "--show-current"],
                capture_output=True, text=True, timeout=2,
            )
            ctx["git_branch"] = branch.stdout.strip() or "(detached)"
            status = subprocess.run(
                ["git", "status", "--porcelain"],
                capture_output=True, text=True, timeout=2,
            )
            ctx["git_dirty"] = bool(status.stdout.strip())
        else:
            ctx["git_repo"] = False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        ctx["git_repo"] = False

    try:
        entries = sorted(os.listdir(ctx["cwd"]))[:MAX_DIR_ENTRIES]
        ctx["ls"] = entries
    except OSError:
        ctx["ls"] = []

    ctx["history"] = _read_zsh_history()
    return ctx


def _read_zsh_history():
    hist_file = os.environ.get("HISTFILE")
    if not hist_file or not os.path.exists(hist_file):
        return []
    try:
        with open(hist_file, "rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - 16384))
            raw = f.read().decode("utf-8", errors="replace")
    except OSError:
        return []
    out = []
    for line in raw.splitlines():
        if line.startswith(":"):
            idx = line.find(";")
            if idx >= 0:
                line = line[idx + 1:]
        line = line.strip()
        if line:
            out.append(line)
    return out[-MAX_HISTORY_LINES:]


def format_context_block(ctx):
    parts = ["<context>"]
    parts.append(f"OS: {ctx.get('distro') or ctx.get('platform', 'unknown')}")
    parts.append(f"Shell: {ctx['shell']}")
    parts.append(f"PWD: {ctx['cwd']}")
    if ctx.get("git_repo"):
        dirty = " (dirty)" if ctx.get("git_dirty") else ""
        parts.append(f"Git: branch={ctx.get('git_branch', '?')}{dirty}")
    else:
        parts.append("Git: not a repo")
    if ctx.get("ls"):
        joined = ", ".join(ctx["ls"])
        parts.append(f"PWD contents ({len(ctx['ls'])} entries): {joined}")
    if ctx.get("history"):
        parts.append("Recent shell history:")
        for cmd in ctx["history"]:
            parts.append(f"  $ {cmd}")
    parts.append("</context>")
    return "\n".join(parts)


# ---------- Rendering ----------

def render_commands(plan, commands):
    if plan:
        CONSOLE.print(Panel(plan, title="[bold cyan]Plan[/bold cyan]", border_style="cyan"))
    for i, cmd in enumerate(commands, 1):
        danger = cmd.get("danger", "safe")
        purpose = cmd.get("purpose", "execute")
        color = {"safe": "green", "caution": "yellow", "destructive": "red"}.get(danger, "white")
        header = Text()
        header.append(f"[{i}] ", style="bold")
        header.append(cmd.get("description", ""))
        header.append(f"  • {danger}", style=color)
        if purpose == "gather_info":
            header.append("  • info-gather", style="dim")
        CONSOLE.print(header)
        syntax = Syntax(
            cmd.get("command", ""), "bash",
            theme="ansi_dark", line_numbers=False, word_wrap=True,
        )
        CONSOLE.print(Panel(syntax, border_style="dim"))


def render_answer(text):
    CONSOLE.print(Panel(
        Markdown(text or ""), title="[bold cyan]Answer[/bold cyan]",
        border_style="cyan",
    ))


def _extract_error_message(raw):
    """Pull just the human-readable message out of a SDK error string.

    Provider exceptions stringify to deeply-nested dicts like:
        429 RESOURCE_EXHAUSTED. {'error': {'code': 429, 'message': '...', ...}}
    We want the inner message; fall back to the raw string."""
    s = str(raw)
    for marker in ("'message':", '"message":'):
        idx = s.find(marker)
        if idx < 0:
            continue
        tail = s[idx + len(marker):].lstrip()
        if tail and tail[0] in ("'", '"'):
            quote = tail[0]
            end = tail.find(quote, 1)
            if end > 0:
                return tail[1:end]
    return s


def render_api_error(provider, raw):
    err = str(raw)
    short = _extract_error_message(raw)
    quota = any(
        k in err.lower()
        for k in ("429", "resource_exhausted", "rate limit", "rate_limit", "quota", "insufficient_quota")
    )
    if quota:
        others = [p.name for k, p in PROVIDERS.items() if k != provider.key]
        body = (
            f"[yellow]{provider.name} rate-limited or quota exhausted.[/yellow]\n\n"
            f"{short[:500]}\n\n"
            f"[bold]Workarounds:[/bold]\n"
            f"  • Wait, then retry\n"
            f"  • Switch provider:  [cyan]enigma ai config[/cyan]  "
            f"(others: {', '.join(others)})\n"
            f"  • One-off:  [cyan]AI_PROVIDER=openai enigma ai \"...\"[/cyan]"
        )
        CONSOLE.print(Panel(
            body, title=f"[bold]Rate limit — {provider.name}[/bold]",
            border_style="yellow",
        ))
        return
    CONSOLE.print(Panel(
        f"[red]{short[:600]}[/red]",
        title=f"[bold]{provider.name} API error[/bold]",
        border_style="red",
    ))


def show_setup_needed(provider):
    CONSOLE.print(Panel(
        f"[red]{provider.api_key_env} not set.[/red]\n\n"
        f"Get a key at {provider.setup_url}, then store it:\n"
        f"  [cyan]enigma env add ai {provider.api_key_env}=<your-key>[/cyan]\n\n"
        "Reload your shell after adding.\n\n"
        f"Or switch provider: [cyan]enigma ai config[/cyan]",
        title=f"[bold]Setup needed — {provider.name}[/bold]",
        border_style="red",
    ))


# ---------- Execution ----------

def confirm_command(cmd):
    danger = cmd.get("danger", "safe")
    if danger == "destructive":
        prompt = inquirer.text(
            message="Type 'yes' to run this destructive command (anything else aborts):",
            style=STYLE, vi_mode=True,
        )
        ans = prompt_with_interrupt_handler(prompt)
        return ans.strip().lower() == "yes"
    default = danger == "safe"
    label = "Run this command?" if danger == "safe" else "Run this command? (caution)"
    confirm = inquirer.confirm(message=label, default=default, style=STYLE, vi_mode=True)
    return prompt_with_interrupt_handler(confirm)


def execute_command(cmd_str):
    CONSOLE.print(f"[dim]$ {cmd_str}[/dim]")
    try:
        proc = subprocess.Popen(
            ["zsh", "-c", cmd_str],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1,
        )
    except FileNotFoundError:
        return 127, "zsh not found"
    captured = []
    try:
        for line in iter(proc.stdout.readline, ""):
            sys.stdout.write(line)
            sys.stdout.flush()
            captured.append(line)
        proc.stdout.close()
        rc = proc.wait()
    except KeyboardInterrupt:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
        captured.append("\n[interrupted by user]\n")
        return 130, "".join(captured)
    return rc, "".join(captured)


def truncate(text, limit=MAX_OUTPUT_FEEDBACK):
    if len(text) <= limit:
        return text
    half = limit // 2
    return text[:half] + f"\n...[truncated {len(text) - limit} chars]...\n" + text[-half:]


def handle_questions(questions):
    answers = []
    custom_marker = "[Other — type your own answer]"
    for q in questions:
        choices = list(q.get("options") or [])
        if q.get("allow_custom") and custom_marker not in choices:
            choices = choices + [custom_marker]
        if not choices:
            prompt = inquirer.text(message=q["text"], style=STYLE, vi_mode=True)
            ans = prompt_with_interrupt_handler(prompt)
        else:
            select = inquirer.select(
                message=q["text"], choices=choices,
                vi_mode=True, style=STYLE,
            )
            ans = prompt_with_interrupt_handler(select)
            if ans == custom_marker:
                free = inquirer.text(message="Your answer:", style=STYLE, vi_mode=True)
                ans = prompt_with_interrupt_handler(free)
        answers.append({"question": q["text"], "answer": ans})
    return answers


# ---------- Chat loop ----------

def run_chat(provider, client, model, initial_prompt):
    contents = []
    ctx = get_context()
    contents.append({
        "role": "user",
        "content": format_context_block(ctx) + "\n\n" + initial_prompt,
    })

    while True:
        with CONSOLE.status(
            f"[cyan]Thinking ({provider.name} · {model})...[/cyan]",
            spinner="dots",
        ):
            status, payload = provider.call(
                client, model, contents, RESPONSE_SCHEMA, SYSTEM_PROMPT,
            )
        if status == "error":
            render_api_error(provider, payload)
            return 1
        reply = payload

        contents.append({"role": "assistant", "content": json.dumps(reply)})

        kind = reply.get("kind")
        reasoning = reply.get("reasoning") or ""
        if reasoning:
            CONSOLE.print(f"[dim italic]→ {reasoning}[/dim italic]")

        if kind == "questions":
            qs = reply.get("questions") or []
            if not qs:
                CONSOLE.print("[yellow]AI returned no questions; ending.[/yellow]")
                return 0
            answers = handle_questions(qs)
            reply_text = "\n".join(
                f"Q: {a['question']}\nA: {a['answer']}" for a in answers
            )
            contents.append({"role": "user", "content": reply_text})
            continue

        if kind == "answer":
            render_answer(reply.get("answer", ""))
        elif kind == "commands":
            commands = reply.get("commands") or []
            plan = reply.get("plan") or ""
            if not commands:
                CONSOLE.print("[yellow]AI returned no commands.[/yellow]")
            else:
                render_commands(plan, commands)
                results = []
                for cmd in commands:
                    if not confirm_command(cmd):
                        CONSOLE.print("[yellow]Skipped.[/yellow]")
                        results.append({
                            "command": cmd.get("command", ""),
                            "skipped": True,
                        })
                        continue
                    rc, out = execute_command(cmd.get("command", ""))
                    results.append({
                        "command": cmd.get("command", ""),
                        "exit_code": rc,
                        "output": truncate(out),
                    })
                feedback = "Execution results:\n" + json.dumps(results, indent=2)
                contents.append({"role": "user", "content": feedback})
        else:
            CONSOLE.print(f"[red]Unknown response kind: {kind}[/red]")

        try:
            CONSOLE.print()
            followup = inquirer.text(
                message="Follow-up (Enter to exit):",
                style=STYLE, vi_mode=True,
            ).execute()
        except KeyboardInterrupt:
            CONSOLE.print("\n[yellow]Bye.[/yellow]")
            return 0
        if not followup.strip():
            return 0
        ctx = get_context()
        contents.append({
            "role": "user",
            "content": format_context_block(ctx) + "\n\n" + followup,
        })


# ---------- Config UI ----------

def show_config(config):
    table = Table(title="enigma ai config", title_style="bold")
    table.add_column("Provider")
    table.add_column("Model")
    table.add_column("API key")
    table.add_column("Active", justify="center")
    for key, p in PROVIDERS.items():
        active = "✓" if key == config["provider"] else ""
        model = config["models"].get(key, p.default_model)
        key_set = (
            "[green]✓ set[/green]"
            if os.environ.get(p.api_key_env)
            else f"[red]✗ unset[/red] (${p.api_key_env})"
        )
        style = "cyan" if key == config["provider"] else None
        table.add_row(p.name, model, key_set, active, style=style)
    CONSOLE.print(table)
    CONSOLE.print(
        "\nConfig file: [dim]~/.cache/zsh/ai_config.json[/dim]\n"
        "Override at runtime with $AI_PROVIDER / $OPENAI_MODEL / $GEMINI_MODEL / $ANTHROPIC_MODEL."
    )


def handle_config(action):
    """action: None (interactive) or "show"."""
    config = load_config()
    if action == "show":
        show_config(config)
        return 0

    # Interactive: pick provider, then model for that provider.
    provider_choices = [{"name": p.name, "value": p.key} for p in PROVIDERS.values()]
    select = inquirer.select(
        message="Active provider:",
        choices=provider_choices,
        default=config["provider"],
        vi_mode=True, style=STYLE,
    )
    new_provider_key = prompt_with_interrupt_handler(select)
    provider = PROVIDERS[new_provider_key]

    current_model = config["models"].get(new_provider_key, provider.default_model)
    custom_marker = "[Other — type a custom model ID]"
    model_choices = list(provider.suggested_models)
    if current_model not in model_choices:
        model_choices.insert(0, current_model)
    model_choices.append(custom_marker)

    select_model = inquirer.select(
        message=f"Model for {provider.name}:",
        choices=model_choices,
        default=current_model,
        vi_mode=True, style=STYLE,
    )
    chosen = prompt_with_interrupt_handler(select_model)
    if chosen == custom_marker:
        text = inquirer.text(
            message="Model ID:", default=current_model,
            style=STYLE, vi_mode=True,
        )
        chosen = prompt_with_interrupt_handler(text).strip()
        if not chosen:
            CONSOLE.print("[yellow]No model entered; keeping current.[/yellow]")
            chosen = current_model

    config["provider"] = new_provider_key
    config["models"][new_provider_key] = chosen
    save_config(config)

    CONSOLE.print(
        f"\n[green]✓ Saved.[/green] Active: "
        f"[cyan]{provider.name}[/cyan] · [cyan]{chosen}[/cyan]"
    )
    if not os.environ.get(provider.api_key_env):
        CONSOLE.print(
            f"[yellow]Heads-up:[/yellow] ${provider.api_key_env} is not set.\n"
            f"  enigma env add ai {provider.api_key_env}=<your-key>\n"
            f"  Get a key: {provider.setup_url}"
        )
    return 0


# ---------- Entry point ----------

def main():
    parser = argparse.ArgumentParser(
        prog="enigma ai",
        description="AI shell assistant (OpenAI / Gemini / Anthropic).",
    )
    parser.add_argument(
        "--config", action="store_true",
        help="Open the config UI (or pass 'show' as the next arg to just view).",
    )
    parser.add_argument(
        "request", nargs="*",
        help="Your request. Omit to prompt interactively.",
    )
    args = parser.parse_args()

    if args.config:
        sub = args.request[0] if args.request else None
        return handle_config(sub)

    config = load_config()
    provider, model = resolve(config)

    api_key = os.environ.get(provider.api_key_env)
    if not api_key:
        show_setup_needed(provider)
        return 1

    try:
        client = provider.create_client(api_key)
    except ImportError:
        CONSOLE.print(
            f"[red]{provider.package} not installed in venv. Run:[/red]\n"
            f"  {sys.executable} -m pip install {provider.package}"
        )
        return 1

    if args.request:
        initial = " ".join(args.request)
    else:
        try:
            initial = inquirer.text(
                message="What do you want to do?",
                style=STYLE, vi_mode=True,
            ).execute()
        except KeyboardInterrupt:
            return 0
        if not initial.strip():
            return 0

    try:
        return run_chat(provider, client, model, initial)
    except KeyboardInterrupt:
        CONSOLE.print("\n[yellow]Interrupted.[/yellow]")
        return 130


if __name__ == "__main__":
    sys.exit(main() or 0)
