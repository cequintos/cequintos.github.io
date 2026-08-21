document.addEventListener("DOMContentLoaded", () => {
    // 1. Estructura de datos del sistema de archivos
    const fileSystem = {
        "/": [
            { name: "scripts/", type: "dir", date: "2026-01-18 09:15", size: "-", target: "/scripts" },
            { name: "pc-lifecycle.exe", type: "file", icon: "📜", date: "2026-02-12 18:45", size: "4.2 KB", url: "downloads/pc-lifecycle.exe" },
            { name: "ricoh-driver.zip", type: "file", icon: "📦", date: "2026-01-29 11:02", size: "15.4 MB", url: "downloads/ricoh_driver.zip" }
        ],
        "/scripts": [
            { name: "apps-installer-online.ps1", type: "file", icon: "🐍", date: "2025-11-04 16:30", size: "8.1 KB", url: "downloads/scripts/apps-installer-online.ps1" },
            { name: "app-installer.bat", type: "file", icon: "🐍", date: "2025-11-04 16:30", size: "8.1 KB", url: "downloads/scripts/app-installer.bat" }
        ]
    };

    let currentPath = "/";

    // 2. Referencias del DOM
    const tableBody = document.getElementById("file-table-body");
    const terminalTitle = document.getElementById("terminal-title");

    // 3. Función principal de renderizado
    const renderDirectory = (path) => {
        const items = fileSystem[path];
        if (!items) return;

        currentPath = path;

        // Actualizar título de la terminal
        if (terminalTitle) {
            terminalTitle.textContent = `cequintos@sys:~/$ ls -la /downloads${path === "/" ? "" : path}`;
        }

        // Limpiar tabla
        tableBody.innerHTML = "";

        // Agregar enlace '../' para subir de nivel si no estamos en la raíz
        if (path !== "/") {
            const parentPath = getParentPath(path);
            const parentRow = document.createElement("tr");
            parentRow.innerHTML = `
                <td class="file-table__name"><span aria-hidden="true">📁</span> <a href="#" class="nav-dir" data-target="${parentPath}">../</a></td>
                <td>-</td>
                <td>-</td>
                <td><a href="#" class="file-table__link nav-dir" data-target="${parentPath}">[ Volver ]</a></td>
            `;
            tableBody.appendChild(parentRow);
        }

        // Renderizar elementos del directorio actual
        items.forEach(item => {
            const row = document.createElement("tr");

            if (item.type === "dir") {
                row.innerHTML = `
                    <td class="file-table__name"><span aria-hidden="true">📁</span> <a href="#" class="nav-dir" data-target="${item.target}">${item.name}</a></td>
                    <td>${item.date}</td>
                    <td>${item.size}</td>
                    <td><a href="#" class="file-table__link nav-dir" data-target="${item.target}">[ Explorar ]</a></td>
                `;
            } else {
                row.innerHTML = `
                    <td class="file-table__name"><span aria-hidden="true">${item.icon || "📄"}</span> <a href="${item.url}" download>${item.name}</a></td>
                    <td>${item.date}</td>
                    <td>${item.size}</td>
                    <td><a href="${item.url}" class="file-table__link" download>[ Descargar ]</a></td>
                `;
            }

            tableBody.appendChild(row);
        });
    };

    // Helper para obtener el directorio padre
    const getParentPath = (path) => {
        const segments = path.split("/").filter(Boolean);
        segments.pop();
        return segments.length === 0 ? "/" : "/" + segments.join("/");
    };

    // 4. Delegación de eventos para la navegación
    tableBody.addEventListener("click", (e) => {
        const target = e.target.closest(".nav-dir");
        if (target) {
            e.preventDefault();
            const destination = target.getAttribute("data-target");
            renderDirectory(destination);
        }
    });

    // Carga inicial
    renderDirectory("/");
});