# COEASY - Oracle Forms & Reports Repository

This repository contains the source code for the COEASY application. We follow a strict separation between **Binaries** (for development) and **XML/Plain Text** (for version control and code review).



---

## 📂 Repository Structure

| Folder Path | Description | File Types |
| :--- | :--- | :--- |
| `src/database/` | All PL/SQL logic (Packages, Triggers, Views) | `.pks`, `.pkb`, `.sql` |
| `src/forms/**/bin` | **Source Binaries** used in Forms Builder | `.fmb`, `.mmb`, `.pll` |
| `src/forms/**/xml` | **Text Representations** for Git Diffs | `.xml` |
| `src/reports/bin` | Oracle Reports source binaries | `.rdf` |
| `src/reports/xml` | Oracle Reports converted text/xml | `.xml` / `.rex` |
| `assets/java` | Java components for use in modules | `.jar`, `.zip` |
| `assets/scripts` | Shell/Batch scripts for automation | `.bat`, `.sh` |

---

## 🛠 Developer Workflow

To ensure code reviews are possible, **never commit a binary change without its corresponding XML update.**

### 1. Modifying a Form
1. Open the `.fmb` from `src/forms/modules/bin/`.
2. Apply your changes and save.
3. Run the conversion script (located in `assets/scripts`) to update the XML in `src/forms/modules/xml/`.
4. Stage **both** the `.fmb` and the `.xml` in your Git commit.

### 2. Database Changes
* **Packages:** Split into `.pks` (Specification) and `.pkb` (Body) in their respective folders.
* **Format:** Use UTF-8 encoding for all SQL scripts.

---

## 🚫 What NOT to Commit
The following files are excluded via `.gitignore` and should never be pushed to the repository:
* Compiled binaries: `*.fmx`, `*.mmx`, `*.plx`, `*.rep`
* Local logs/errors: `*.err`, `*.log`
* Desktop/System files: `Thumbs.db`, `.DS_Store`

---

## 🚀 Deployment
Deployment to the UAT/Production environments should be handled by compiling the source binaries (`.fmb`, `.pll`, etc.) directly on the application server to ensure compatibility with the server's Oracle Middleware version.