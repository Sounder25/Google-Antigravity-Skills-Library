import os
import glob
import subprocess
import json

from mcp.server.fastmcp import FastMCP

# Initialize Server
server = FastMCP("Antigravity Skills")

SKILLS_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

@server.tool()
def list_skills() -> str:
    """Lists all available Antigravity skills."""
    skills = []
    # Find all SKILL.md files
    for skill_file in glob.glob(os.path.join(SKILLS_ROOT, "**", "SKILL.md"), recursive=True):
        skill_dir = os.path.dirname(skill_file)
        skill_name = os.path.basename(skill_dir)
        skills.append(skill_name)
    return "\n".join(sorted(skills))

@server.tool()
def run_skill(skill_id: str, args: str = "") -> str:
    """
    Executes a skill by ID (e.g., '00_workspace_forensics').
    args: Command line arguments for the script (e.g. '-WorkspacePath .')
    """
    skill_dir = os.path.join(SKILLS_ROOT, skill_id)
    if not os.path.exists(skill_dir):
        return f"Error: Skill '{skill_id}' not found."

    # Look for the .ps1 script
    ps_files = glob.glob(os.path.join(skill_dir, "*.ps1"))
    if not ps_files:
        return f"Error: No .ps1 script found in {skill_id}."
    
    script_path = ps_files[0]
    
    # Construct command
    # powershell -NoProfile -ExecutionPolicy Bypass -File <script> <args>
    cmd = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script_path] + args.split()
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        output = f"Exit Code: {result.returncode}\n\nSTDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        return output
    except Exception as e:
        return f"Execution failed: {str(e)}"

@server.tool()
def read_skill_spec(skill_id: str) -> str:
    """Reads the SKILL.md specification for a given skill."""
    skill_file = os.path.join(SKILLS_ROOT, skill_id, "SKILL.md")
    if not os.path.exists(skill_file):
        return "Skill not found."
    with open(skill_file, "r", encoding="utf-8") as f:
        return f.read()

if __name__ == "__main__":
    server.run()
