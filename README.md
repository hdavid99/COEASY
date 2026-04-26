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



# 🚀 Proyecto COEASY: Estándares de Desarrollo Oracle Forms & Reports

Este repositorio centraliza el código fuente del sistema **COEASY**. Debido a que el stack de Oracle utiliza archivos binarios (`.fmb`, `.mmb`, `.pll`, `.rdf`), implementamos una metodología de **Bloqueo de Archivos (File Locking)** y **Versionamiento Espejo (XML)** para garantizar la integridad y facilitar las revisiones de código.

---

## 🛠️ Configuración Obligatoria del Entorno

Para colaborar en este proyecto, es indispensable configurar las siguientes herramientas en **VS Code**:

1. **Git LFS** (por *Joffrey Devey*): Proporciona la interfaz visual para bloquear/desbloquear archivos.
2. **GitLens** (por *GitKraken*): Permite visualizar quién tiene el "Lock" de un módulo directamente en el explorador.

---

## 🔒 Flujo de Trabajo: Gestión de Binarios

Los archivos binarios de Oracle **no se pueden fusionar (merge)**. Para evitar la pérdida de cambios por sobreescritura, aplicamos estrictamente el flujo **Lock-Modify-Unlock**:

1. **BLOQUEAR (Lock):** Antes de abrir un archivo en el Builder, haz clic derecho en VS Code y selecciona `Git LFS: Lock`. 
   * *Si el archivo ya está bloqueado, Git te indicará el nombre del compañero que lo tiene.*
2. **MODIFICAR:** Realiza tus cambios en Oracle Forms/Reports Builder.
3. **CONVERTIR (XML):** Ejecuta el script `convert_single_forms.bat` (o el de Reports) para generar la versión de texto en la carpeta `/xml/`. **Este paso es vital para el Code Review.**
4. **COMMIT & PUSH:** Sube tanto el binario modificado como su respectivo XML generado.
5. **LIBERAR (Unlock):** Una vez que el `push` sea exitoso en GitHub, libera el archivo mediante `Git LFS: Unlock`.

> ⚠️ **IMPORTANTE:** Los archivos están configurados como **"Solo Lectura"** por defecto. Si el Builder no te deja guardar, es la señal de que olvidaste realizar el **Lock**.

---

## 📂 Estructura del Repositorio

| Carpeta | Contenido | Tipo de Gestión |
| :--- | :--- | :--- |
| `src/forms/modules/bin` | Módulos `.fmb` | **Git LFS (Bloqueable)** |
| `src/forms/modules/xml` | Fuentes `.xml` | Git Estándar (Texto) |
| `src/reports/bin` | Reportes `.rdf` | **Git LFS (Bloqueable)** |
| `src/reports/xml` | Fuentes `.xml` | Git Estándar (Texto) |
| `src/database/` | SQL, PKS, PKB, Triggers | Git Estándar (Texto) |
| `docs/` | Manuales y Diseño | Git Estándar |

---

## 🤖 Scripts de Automatización (DevOps)

Disponemos de herramientas en la raíz para facilitar las tareas diarias:

* **`convert_all_forms.bat`**: Convierte todos los binarios de Forms a XML de forma masiva.
* **`convert_single_report.bat`**: Solicita la ruta de un solo reporte para convertirlo a XML.
* **`check_locks.bat`**: Muestra en consola la lista de archivos bloqueados actualmente en el servidor.
* **`assets/scripts/frmxml2f.bat`**: Importa XML a FMB con validación de `RecordGroupQuery`, normalización de entidades (`&amp;#10;`, `&amp;#13;`, `&amp;#9;`) y verificación round-trip (`frmxml2f` + `frmf2xml`).

Ejemplo:

`assets\\scripts\\frmxml2f.bat src\\forms\\modules\\xml\\COCOPE_1_fmb.xml`

---

## 🚫 Políticas de Exclusión (.gitignore)

Para mantener el repositorio limpio y ligero, **NUNCA** se deben subir:
* **Compilados:** `.fmx`, `.mmx`, `.plx`, `.rep`.
* **Temporales:** `.err`, `.log`, `.out`, `.bak`.
* **Configuración Local:** Carpeta `.vscode/` (personales).

---
© 2026 COEASY DevOps Team.